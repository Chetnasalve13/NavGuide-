import 'package:flutter/material.dart';

class SavedRoutesPage extends StatefulWidget {
  const SavedRoutesPage({Key? key}) : super(key: key);

  @override
  _SavedRoutesPageState createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage> {
  String? _selectedCurrentPosition;
  String? _selectedDestination;
  bool _startEnabled = false;
  List<Offset> _finalPath = [];

  // Sample positions for dropdowns
  List<String> _positions = [
    'Staff Room 1',
    'Staff Room 2',
    'HOD Cabin',
    'Class 301',
    'Class 302',
    'Class 303',
    'Lab A',
    'Lab B',
    'Lab C',
    'Staircase 1',
    'Staircase 2',
    'Washroom 1',
    'Washroom 2'
  ];
  List<String> _destinations = [
    'Staff Room 1',
    'Staff Room 2',
    'HOD Cabin',
    'Class 301',
    'Class 302',
    'Class 303',
    'Lab A',
    'Lab B',
    'Lab C',
    'Staircase 1',
    'Staircase 2',
    'Washroom 1',
    'Washroom 2'
  ];

  final Map<String, Offset> _roomPoints = {
    'Staff Room 1': Offset(330, 440),
    'Staff Room 2': Offset(305, 425),
    'HOD Cabin': Offset(710, 460),
    'Class 301': Offset(410, 400),
    'Class 302': Offset(380, 390),
    'Class 303': Offset(715, 495),
    'Lab A': Offset(625, 495),
    'Lab B': Offset(600, 495),
    'Lab C': Offset(645, 460),
    'Staircase 1': Offset(820, 500),
    'Staircase 2': Offset(160, 200),
    'Washroom 1': Offset(835, 460),
    'Washroom 2': Offset(250, 215),
  };

  // Common pathway polyline
  final List<Offset> _commonPathway = [
    // straight down from up
    Offset(195, 200),
    Offset(195, 220),
    Offset(195, 240),
    Offset(195, 280),
    Offset(195, 320),
    Offset(195, 330),
    Offset(195, 350),
//  inclined down
    Offset(255, 375),
    // Offset(340, 410),
    Offset(355, 415),
    Offset(465, 460),
    Offset(535, 485),
    // horizontal left to right
    Offset(595, 485),
    Offset(620, 485),
    Offset(650, 485),
    Offset(700, 485),
    Offset(820, 485),
    Offset(835, 475),
    Offset(870, 485),
  ];

  void _checkIfStartEnabled() {
    if (_selectedCurrentPosition != null && _selectedDestination != null) {
      setState(() {
        _startEnabled = true;
      });
    }
  }

  Offset _getNearestPointOnPathway(Offset roomPoint) {
    double minDistance = double.infinity;
    Offset nearestPoint = _commonPathway.first;

    for (var point in _commonPathway) {
      double distance = (roomPoint - point).distance;
      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = point;
      }
    }
    return nearestPoint;
  }

  void _startNavigation() {
    if (_selectedCurrentPosition != null && _selectedDestination != null) {
      setState(() {
        _finalPath.clear();

        Offset startRoomPoint = _roomPoints[_selectedCurrentPosition!]!;
        Offset destinationRoomPoint = _roomPoints[_selectedDestination!]!;

        Offset startPathwayPoint = _getNearestPointOnPathway(startRoomPoint);
        Offset destinationPathwayPoint =
            _getNearestPointOnPathway(destinationRoomPoint);

        // Add start point and nearest pathway point
        _finalPath.add(startRoomPoint);
        _finalPath.add(startPathwayPoint);

        // Get indices for the path segment
        int startIndex = _commonPathway.indexOf(startPathwayPoint);
        int destinationIndex = _commonPathway.indexOf(destinationPathwayPoint);

        // Ensure proper direction of traversal
        if (startIndex < destinationIndex) {
          // Forward direction
          for (int i = startIndex; i <= destinationIndex; i++) {
            _finalPath.add(_commonPathway[i]);
          }
        } else {
          // Reverse direction
          for (int i = startIndex; i >= destinationIndex; i--) {
            _finalPath.add(_commonPathway[i]);
          }
        }

        // Add the destination pathway and room points
        _finalPath.add(destinationPathwayPoint);
        _finalPath.add(destinationRoomPoint);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapViewPage(waypoints: _finalPath),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Saved Routes'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Text(
              'Select your current position:',
              style: TextStyle(fontSize: 18),
            ),
            DropdownButton<String>(
              value: _selectedCurrentPosition,
              items: _positions.map((String position) {
                return DropdownMenuItem<String>(
                  value: position,
                  child: Text(position),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCurrentPosition = value;
                });
                _checkIfStartEnabled();
              },
              hint: Text('Select Current Position'),
            ),
            const SizedBox(height: 30),
            Text(
              'Select your destination:',
              style: TextStyle(fontSize: 18),
            ),
            DropdownButton<String>(
              value: _selectedDestination,
              items: _destinations.map((String destination) {
                return DropdownMenuItem<String>(
                  value: destination,
                  child: Text(destination),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDestination = value;
                });
                _checkIfStartEnabled();
              },
              hint: Text('Select Destination'),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _startEnabled ? _startNavigation : null,
              child: Text('Start Navigation'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapViewPage extends StatefulWidget {
  final List<Offset> waypoints;
  final double originalImageWidth = 1024;
  final double originalImageHeight = 768;

  const MapViewPage({
    Key? key,
    required this.waypoints,
  }) : super(key: key);

  @override
  _MapViewPageState createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  Offset? _tappedPosition;

  void _handleTap(TapUpDetails details, BuildContext context) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localPosition = box.globalToLocal(details.globalPosition);

    final Size displayedSize = box.size;

    final double scaleX = widget.originalImageWidth / displayedSize.width;
    final double scaleY = widget.originalImageHeight / displayedSize.height;

    final Offset scaledPosition = Offset(
      localPosition.dx * scaleX,
      localPosition.dy * scaleY,
    );

    setState(() {
      _tappedPosition = scaledPosition;
    });

    print('Tapped position: $scaledPosition (scaled to original image)');
  }

  void _adjustTappedPosition(double dx) {
    if (_tappedPosition != null) {
      setState(() {
        _tappedPosition = Offset(_tappedPosition!.dx + dx, _tappedPosition!.dy);
      });
      print('Adjusted tapped position: $_tappedPosition');
    }
  }

  void _adjustTappedPositionVertical(double dy) {
    if (_tappedPosition != null) {
      setState(() {
        _tappedPosition = Offset(_tappedPosition!.dx, _tappedPosition!.dy + dy);
      });
      print('Adjusted tapped position: $_tappedPosition');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Map View'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) => _handleTap(details, context),
                  child: Stack(
                    children: [
                      Center(
                        child: Image.asset(
                          'assets/images/map.png',
                          fit: BoxFit.contain,
                          width: widget.originalImageWidth,
                          height: widget.originalImageHeight,
                        ),
                      ),
                      CustomPaint(
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        painter: MapPainter(
                          waypoints: widget.waypoints,
                          imageSize: Size(
                            widget.originalImageWidth,
                            widget.originalImageHeight,
                          ),
                          tappedPosition: _tappedPosition,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => _adjustTappedPosition(-1.0),
                  child: Icon(Icons.arrow_left),
                ),
                ElevatedButton(
                  onPressed: () => _adjustTappedPosition(1.0),
                  child: Icon(Icons.arrow_right),
                ),
                ElevatedButton(
                  onPressed: () => _adjustTappedPositionVertical(-1.0),
                  child: Icon(Icons.arrow_drop_up),
                ),
                ElevatedButton(
                  onPressed: () => _adjustTappedPositionVertical(1.0),
                  child: Icon(Icons.arrow_drop_down),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final List<Offset> waypoints;
  final Size imageSize;
  final Offset? tappedPosition;

  MapPainter({
    required this.waypoints,
    required this.imageSize,
    this.tappedPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    if (waypoints.isNotEmpty) {
      Path path = Path();
      path.moveTo(
        waypoints.first.dx * size.width / imageSize.width,
        waypoints.first.dy * size.height / imageSize.height,
      );
      for (var waypoint in waypoints.skip(1)) {
        path.lineTo(
          waypoint.dx * size.width / imageSize.width,
          waypoint.dy * size.height / imageSize.height,
        );
      }
      canvas.drawPath(path, paint);

      // Draw a red circle at the start and end of the path
      final Paint StartPointCircle = Paint()..color = Colors.red;
      final Paint EndPointCircle = Paint()..color = Colors.green;
      final double circleRadius = 10.0;

      // Draw circle at the start point
      Offset startPoint = Offset(
        waypoints.first.dx * size.width / imageSize.width,
        waypoints.first.dy * size.height / imageSize.height,
      );
      canvas.drawCircle(startPoint, circleRadius, StartPointCircle);

      // Draw circle at the end point
      Offset endPoint = Offset(
        waypoints.last.dx * size.width / imageSize.width,
        waypoints.last.dy * size.height / imageSize.height,
      );
      canvas.drawCircle(endPoint, circleRadius, EndPointCircle);
    }

    // Optional: Draw a red circle at tapped position if it exists
    if (tappedPosition != null) {
      canvas.drawCircle(
        Offset(
          tappedPosition!.dx * size.width / imageSize.width,
          tappedPosition!.dy * size.height / imageSize.height,
        ),
        8.0,
        Paint()..color = Colors.red,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

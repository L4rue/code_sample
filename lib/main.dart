import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GOOGLE MAP FLASH',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Google Map Flash'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[Expanded(child: MapWidget())],
        ),
      ),
    );
  }
}

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<StatefulWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  final Completer<GoogleMapController> _mapController = Completer<GoogleMapController>();
  late final GoogleMapController controller;
  static const defaultZoom = 16.0;
  late List<Marker> markersList = markersNotifier.markerList;
  late int lastRebuildTime;

  @override
  void initState() {
    super.initState();

    nowIndexProvider.addListener(() {
      if (nowIndexProvider.nowIndex != -1) {
        CameraPosition cameraPos = CameraPosition(target: getlocation[nowIndexProvider.nowIndex], zoom: defaultZoom);
        controller.animateCamera(CameraUpdate.newCameraPosition(cameraPos));
      }

      if (nowIndexProvider.nowIndex == -1) {
        // set all marker to default color
        markersNotifier.changeMarker(nowIndexProvider.oldIndex, BitmapDescriptor.defaultMarker, 0);
      } else if (nowIndexProvider.oldIndex != -1 && nowIndexProvider.oldIndex! < getlocation.length) {
        // change the target marker to special color
        markersNotifier.changeMarker(nowIndexProvider.oldIndex, BitmapDescriptor.defaultMarker, 0);
        markersNotifier.changeMarker(nowIndexProvider.nowIndex, BitmapDescriptor.defaultMarkerWithHue(60), 1.0);
      } else {
        // change the target marker to special color
        markersNotifier.changeMarker(nowIndexProvider.nowIndex, BitmapDescriptor.defaultMarkerWithHue(60), 1.0);
      }
    });

    markersNotifier.addListener(() async {
      int rebuildTimeDiff = DateTime.now().millisecondsSinceEpoch - lastRebuildTime;
      if (rebuildTimeDiff < 200) {
        await Future.delayed(Duration(milliseconds: 200 - rebuildTimeDiff));
      }
      setState(() {
        // refresh marker when markersList update
        markersList = markersNotifier.markerList;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // refresh icon after get markersList from backend
      markersNotifier.setState(getMarker());
      controller = await _mapController.future;
    });
  }

  /// a mock of api which returns a list of position
  List<LatLng> getlocation = [
    const LatLng(35.5594, 139.7210),
    const LatLng(35.5604, 139.7210),
    const LatLng(35.5614, 139.7210),
    const LatLng(35.5624, 139.7210),
    const LatLng(35.5634, 139.7210),
    const LatLng(35.5644, 139.7210),
    const LatLng(35.5654, 139.7210),
    const LatLng(35.5664, 139.7210),
    const LatLng(35.5674, 139.7210),
  ];

  getMarker() {
    List<Marker> markerList = [];
    for (var i = 0; i < getlocation.length; i++) {
      var marker = Marker(
        markerId: MarkerId('$i'),
        position: LatLng(getlocation[i].latitude, getlocation[i].longitude),
        icon: BitmapDescriptor.defaultMarker,
        consumeTapEvents: true,
        onTap: () {
          nowIndexProvider.changeIndex(i);
        },
        zIndex: 0,
      );
      markerList.add(marker);
    }
    return markerList;
  }

  @override
  Widget build(BuildContext context) {
    lastRebuildTime = DateTime.now().millisecondsSinceEpoch;

    return GoogleMap(
      mapType: MapType.normal,
      initialCameraPosition: const CameraPosition(target: LatLng(35.5594, 139.7210), zoom: defaultZoom),
      markers: Set.of(markersList),
      onMapCreated: (GoogleMapController controller) {
        if (!_mapController.isCompleted) {
          _mapController.complete(controller);
        }
      },
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      onTap: (argument) async {
        nowIndexProvider.changeIndex(-1);
      },
    );
  }
}

class MarkersNotifier extends ChangeNotifier {
  List<Marker> _markerList = [];

  List<Marker> get markerList => _markerList;

  void changeMarker(int index, BitmapDescriptor bitmap, double zIndex) {
    var item = _markerList[index];
    var marker = Marker(
      markerId: item.markerId,
      position: item.position,
      consumeTapEvents: item.consumeTapEvents,
      icon: bitmap,
      onTap: item.onTap,
      zIndex: zIndex,
    );
    _markerList[index] = marker;
    notifyListeners();
  }

  void setState(List<Marker> markerListTemp) {
    _markerList = markerListTemp;
    notifyListeners();
  }
}

MarkersNotifier markersNotifier = MarkersNotifier();

class NowIndexProvider extends ChangeNotifier {
  int _nowIndex = -1;
  int _oldIndex = -1;

  int get nowIndex => _nowIndex;
  int get oldIndex => _oldIndex;

  changeIndex(int index) {
    _oldIndex = _nowIndex;
    _nowIndex = index;
    notifyListeners();
  }
}

NowIndexProvider nowIndexProvider = NowIndexProvider();

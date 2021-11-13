import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:maps_test/polyliness.dart';

import 'bytes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool mapToggle = false;
  Polyline polyline;
  Position currentLocation;
  GoogleMapController mapController;
  TextEditingController searchAddr = TextEditingController();
  BitmapDescriptor markerIcon1;
  Set<Marker> markers = {};
  List<LatLng> polyPoints = [];
  Set<Polyline> polylines = {};
  double startLat = 40.677939;
  double startLng = -73.941755;
  double endLat = 40.698432;
  double endLng = -73.924038;
  LatLng vehiclePosition;

  var data;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // initMarker(double latitude, double longitude){
  //   mapController.add
  // }

  void initState() {
    super.initState();

    _determinePosition();
  }

  @override
  Widget build(BuildContext context) {
    pixel(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.emoji_transportation),
        onPressed: moveVehicle,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: onMapCreated,
              zoomControlsEnabled: false,
              markers: markers,
              polylines: polylines,
              initialCameraPosition: CameraPosition(
                target: LatLng(5, 7),
                zoom: 10.0,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 15, vertical: 30),
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3), // changes position of shadow
                    ),
                  ],
                  color: Colors.white,
                ),
                child: TextField(
                    controller: searchAddr,
                    decoration: InputDecoration(
                      hintText: "Enter Address",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(15),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.search),
                        onPressed: searchandNavigate,
                        iconSize: 30,
                      ),
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  pixel(BuildContext context) async {
    final Uint8List markerIcon =
        await getBytesFromAsset('assets/car.png', context);
    setState(() {
      markerIcon1 = BitmapDescriptor.fromBytes(markerIcon);
    });
  }

  void moveVehicle() async {
    print(polyPoints.length);
    var i;
    for (i = 0; i < polyPoints.length; i += 1) {
      await Future.delayed(Duration(
        seconds: 3,
      ));

      setState(() {
        markers = {
          Marker(
            markerId: MarkerId("Car is Here"),
            position:
                LatLng(currentLocation.latitude, currentLocation.longitude),
            icon: BitmapDescriptor.defaultMarker,
            infoWindow: InfoWindow(title: "Car 1", snippet: "This is car 1"),
          ),
          Marker(
            markerId: MarkerId("Car is Here"),
            position: polyPoints[i],
            icon: markerIcon1,
            infoWindow: InfoWindow(title: "Car 1", snippet: "This is car 1"),
          )
        };
      });
    }
  }

  void getJsonData() async {
    // Create an instance of Class NetworkHelper which uses http package
    // for requesting data to the server and receiving response as JSON format

    NetworkHelper network = NetworkHelper(
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
    );

    try {
      // getData() returns a json Decoded data
      data = await network.getData();

      // We can reach to our desired JSON data manually as following
      List ls = data['features'][0]['geometry']['coordinates'];

      for (int i = 0; i < ls.length; i++) {
        polyPoints.add(LatLng(ls[i][1], ls[i][0]));
      }
    } catch (e) {
      print(e);
    }
  }

  searchandNavigate() async {
    currentLocation = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best);

    // ignore: await_only_futures
    await getJsonData();
    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(
        target: polyPoints[0],
        //target: LatLng(locations[0].latitude, locations[0].longitude),
        zoom: 50,
      ),
    ));

    print("HEREEEEEEEEEEEEEEE");

    setState(() {
      currentLocation = currentLocation;
      vehiclePosition = polyPoints[0];
      polylines = {
        Polyline(
          polylineId: PolylineId("polyline"),
          points: polyPoints,
          width: 4,
          color: Colors.black,
          startCap: Cap.roundCap,
          endCap: Cap.buttCap,
        )
      };
      markers = {
        Marker(
          markerId: MarkerId("Car is Here"),
          position: LatLng(currentLocation.latitude, currentLocation.longitude),
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: "Car 1", snippet: "This is car 1"),
        ),
        Marker(
          markerId: MarkerId("Car is Here"),
          position: vehiclePosition,
          icon: markerIcon1,
          infoWindow: InfoWindow(title: "Car 1", snippet: "This is car 1"),
        )
      };
    });

    //print(position.latitude);

    // print(searchAddr.text);
    // List<Location> locations = await locationFromAddress(searchAddr.text);
  }

  void onMapCreated(controller) {
    setState(() {
      mapController = controller;
    });
  }
}

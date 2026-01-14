import 'dart:io';
import 'dart:convert';
import 'models.dart';
import 'settings_service.dart';

class CarService {
  final SettingsService _settingsService = SettingsService();
  List<Car> cars = [];
  List<String> favoriteOrder = [];

  // Singleton pattern
  static final CarService _instance = CarService._internal();
  factory CarService() => _instance;
  CarService._internal();

  Future<File> get _carsFile async {
    final basePath = await _settingsService.basePath;
    return File('$basePath/cars.json');
  }

  Future<void> loadCars() async {
    try {
      await _settingsService.ensureDirectoryExists();
      final file = await _carsFile;
      
      if (await file.exists()) {
        final contents = await file.readAsString();
        final dynamic jsonData = json.decode(contents);
        
        if (jsonData is List) {
          cars = jsonData.map((json) => Car.fromJson(json)).toList();
          favoriteOrder = [];
        } else if (jsonData is Map) {
          cars = (jsonData['cars'] as List).map((json) => Car.fromJson(json)).toList();
          favoriteOrder = List<String>.from(jsonData['favoriteOrder'] ?? []);
        }
      } else {
        // Default cars
        cars = [
          Car(name: 'JATO'),
          Car(name: 'Ufology'),
          Car(name: 'Due Process'),
          Car(name: 'Wolfs Bane'),
          Car(name: 'Bulletproof'),
          Car(name: 'Mammoth'),
          Car(name: 'Time machine'),
          Car(name: 'Tiger Express'),
          Car(name: 'Touge'),
          Car(name: 'Papyrus'),
          Car(name: 'Betty'),
          Car(name: 'Memphis'),
          Car(name: 'Alpinist'),
          Car(name: 'Synthwave'),
          Car(name: 'Axel'),
          Car(name: 'Tomcat'),
          Car(name: 'Grandpa Joe'),
          Car(name: 'Falcon'),
          Car(name: 'Cottonmouth'),
          Car(name: 'The Raven'),
          Car(name: 'All Access'),
          Car(name: 'Municipal'),
          Car(name: 'Silver Grey'),
          Car(name: 'Axeman'),
          Car(name: 'Gargantuan'),
          Car(name: 'Crumple Zone'),
          Car(name: 'Thunder'),
          Car(name: 'Milk Truck'),
        ];
        await saveCars();
      }
    } catch (e) {
      throw Exception('Error loading cars: $e');
    }
  }

  Future<void> saveCars() async {
    try {
      await _settingsService.ensureDirectoryExists();
      final file = await _carsFile;
      final jsonData = {
        'cars': cars.map((car) => car.toJson()).toList(),
        'favoriteOrder': favoriteOrder,
      };
      await file.writeAsString(json.encode(jsonData));
    } catch (e) {
      throw Exception('Error saving cars: $e');
    }
  }

  // Helper methods
  void addCar(Car car) {
    cars.add(car);
  }

  void removeCar(int index) {
    cars.removeAt(index);
  }

  void updateCar(int index, Car car) {
    cars[index] = car;
  }

  void toggleCarStatus(int index) {
    cars[index].isDriven = !cars[index].isDriven;
  }

  void toggleFavorite(int index) {
    cars[index].isFavorite = !cars[index].isFavorite;
    
    if (cars[index].isFavorite) {
      if (!favoriteOrder.contains(cars[index].name)) {
        favoriteOrder.add(cars[index].name);
      }
    } else {
      favoriteOrder.remove(cars[index].name);
    }
  }

  void incrementTimesDriven(String carName) {
    final carIndex = cars.indexWhere((car) => car.name == carName);
    if (carIndex != -1) {
      cars[carIndex].timesDriven++;
    }
  }

  void markAllDriven() {
    for (var car in cars) {
      car.isDriven = true;
    }
  }

  void markAllNotDriven() {
    for (var car in cars) {
      car.isDriven = false;
    }
  }
}
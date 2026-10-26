
abstract class Payable {
  double computeEarnings(); 
  String describe(); 
}


mixin Maintainable {
  static const int serviceInterval = 1000; 
  int _kmSinceService = 0;

  String get label; 

  int get kmSinceService => _kmSinceService;
  bool get needsService => _kmSinceService >= serviceInterval;

  void drive(int km) {
    if (km <= 0) {
      print('  [$label] Invalid distance: $km km.');
      return;
    }
    _kmSinceService += km;
    print('  [$label] Drove $km km. Since last service: $_kmSinceService km');
    if (needsService) {
      print('  [$label] ** Service is due! **');
    }
  }

  void service() {
    _kmSinceService = 0;
    print('  [$label] Serviced. Odometer since service reset to 0 km.');
  }
}


class Jeepney with Maintainable implements Payable {
  final String plateNumber;
  final String route;
  final int capacity;
  int _passengers;
  double _baseFare;

  Jeepney(this.plateNumber, this.route, this.capacity, double baseFare)
      : _passengers = 0,
        _baseFare = baseFare;

  @override
  String get label => plateNumber;

  int get passengers => _passengers;
  int get seatsLeft => capacity - _passengers;
  double get baseFare => _baseFare;

  set baseFare(double newFare) {
    if (newFare <= 0) {
      print('  [$plateNumber] Invalid fare: $newFare. Fare not changed.');
      return;
    }
    _baseFare = newFare;
  }

  bool board(int count) {
    if (count <= 0 || count > seatsLeft) {
      print('  [$plateNumber] Cannot board $count passenger(s). '
          'Seats left: $seatsLeft');
      return false;
    }
    _passengers += count;
    print('  [$plateNumber] $count passenger(s) boarded. '
        'Total: $_passengers/$capacity');
    return true;
  }

  void dropOff(int count) {
    if (count <= 0 || count > _passengers) {
      print('  [$plateNumber] Cannot drop off $count passenger(s).');
      return;
    }
    _passengers -= count;
    print('  [$plateNumber] $count passenger(s) got off. '
        'Total: $_passengers/$capacity');
  }

  @override
  double computeEarnings() => _passengers * _baseFare;

  @override
  String describe() => 'Jeepney $plateNumber | Route: $route | '
      'Passengers: $_passengers/$capacity | '
      'Fare: PHP ${_baseFare.toStringAsFixed(2)}';

 
  Future<String> saveTripRecord() async {
    print('  [$plateNumber] Saving trip record to server...');
    await Future.delayed(Duration(seconds: 2)); // simulated delay
    return 'Trip record saved for $plateNumber: '
        '$_passengers passenger(s), '
        'PHP ${computeEarnings().toStringAsFixed(2)}';
  }
}


class ClassicJeepney extends Jeepney {
  int _studentRiders;
  static const double studentDiscount = 0.20;

  ClassicJeepney(String plateNumber, String route, int capacity,
      double baseFare)
      : _studentRiders = 0,
        super(plateNumber, route, capacity, baseFare);


  bool boardStudents(int count) {
    bool ok = board(count);
    if (ok) {
      _studentRiders += count;
      print('  [$plateNumber] $count of them are students (20% discount).');
    }
    return ok;
  }


  @override
  double computeEarnings() {
    int regular = passengers - _studentRiders;
    double studentFare = baseFare * (1 - studentDiscount);
    return (regular * baseFare) + (_studentRiders * studentFare);
  }


  @override
  String describe() => 'Classic  -> ${super.describe()} | '
      'Students: $_studentRiders';
}


class ModernJeepney extends Jeepney {
  final double airconFee;

  ModernJeepney(String plateNumber, String route, int capacity,
      double baseFare, this.airconFee)
      : super(plateNumber, route, capacity, baseFare);

  // POLYMORPHISM: overridden method
  @override
  double computeEarnings() => passengers * (baseFare + airconFee);

  // POLYMORPHISM: overridden method
  @override
  String describe() => 'Modern   -> ${super.describe()} | '
      'Aircon fee: PHP ${airconFee.toStringAsFixed(2)}';
}


class Tricycle with Maintainable {
  final String bodyNumber;

  Tricycle(this.bodyNumber);

  @override
  String get label => 'Tricycle $bodyNumber';
}


Future<void> main() async {
  var jeep1 = ClassicJeepney('ABC 1234', 'Marikina - Cubao', 20, 13.0);
  var jeep2 = ModernJeepney('XYZ 5678', 'Marikina - Sta. Lucia', 16, 15.0, 5.0);
  var jeep3 = ClassicJeepney('DEF 9012', 'Marikina - Antipolo', 18, 14.0);


  List<Jeepney> fleet = [jeep1, jeep2, jeep3];

  print('=== Testing behaviors ===');
  jeep1.boardStudents(5);
  jeep1.board(7);
  jeep2.board(16);
  jeep2.board(2); 
  jeep3.boardStudents(3);
  jeep3.board(4);
  jeep1.dropOff(5);
  jeep3.baseFare = -5;
  jeep3.baseFare = 16.0;

  print('\n=== Fleet status (polymorphic describe) ===');
  for (var jeep in fleet) {
    print(jeep.describe());
  }


  Map<String, double> earnings = {};
  for (var jeep in fleet) {
    earnings[jeep.plateNumber] = jeep.computeEarnings();
  }

  print('\n=== Earnings per jeepney (polymorphic computeEarnings) ===');
  earnings.forEach((plate, amount) {
    print('$plate: PHP ${amount.toStringAsFixed(2)}');
  });

  double total = earnings.values.reduce((a, b) => a + b);
  print('Total fleet earnings: PHP ${total.toStringAsFixed(2)}');


  print('\n=== Using the abstract class Payable as a type ===');
  List<Payable> payables = [jeep1, jeep2, jeep3];
  for (Payable p in payables) {
    print('Earnings: PHP ${p.computeEarnings().toStringAsFixed(2)}');
  }

  
  print('\n=== Mixin: Maintainable (shared by Jeepney and Tricycle) ===');
  var trike = Tricycle('T-045');
  jeep2.drive(600);
  jeep2.drive(450); 
  jeep2.service();
  trike.drive(1200); 
  trike.service();


  print('\n=== Week 11: Async (Future, async/await) ===');

  print('1. Start saving the record of ${jeep1.plateNumber}...');
  Future<String> saving = jeep1.saveTripRecord(); 

 
  print('2. This message prints right away - the program did not freeze.');

  String result = await saving;
  print('3. Result (after the delay): $result');

  print('\nSaving every jeepney, one after another:');
  for (var jeep in fleet) {
    String record = await jeep.saveTripRecord();
    print('   -> $record');
  }
  print('Done. All records saved.');
}

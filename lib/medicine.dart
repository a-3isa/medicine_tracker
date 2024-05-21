class Medicine {
  String name;
  String? imagePath;
  String time;
  DateTime creationDay;
  List<String> hours;
  List<String> days;
  List<String> dates;
  List<bool> checkboxStates;

  Medicine({
    required this.name,
    this.imagePath,
    required this.time,
    required this.hours,
    required this.creationDay,
    required this.checkboxStates,
    required this.days,
    required this.dates,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hours': hours,
      'imagePath': imagePath,
      'checkboxStates': checkboxStates,
      'days': days,
      'dates': dates,
      'time': time,
      'creationDay': creationDay.toIso8601String(),
    };
  }

  // @override
  // String toString() {
  //   return 'Medicine(name: $name, time: $time)';
  // }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      imagePath: json['imagePath'],
      time: json['time'],
      creationDay: DateTime.parse(json['creationDay']),
      hours: List<String>.from(json['hours'] as List),
      checkboxStates: List<bool>.from(json['checkboxStates'] as List),
      days: List<String>.from(json['days'] as List),
      dates: List<String>.from(json['dates'] as List),
    );
  }
}



class Biometrics {
  String measurementDate;
  String? time;
  int? heartRate;
  List<int>? bloodPressure; // List containing systolic and diastolic values
  double? oxygen;
  double? sugar;

  Biometrics({
    required this.measurementDate,
    this.heartRate,
    this.time,
    this.bloodPressure,
    this.oxygen,
    this.sugar,
  });

  Map<String, dynamic> toJson() {
    return {
      'measurementDate': measurementDate,
      'heartRate': heartRate,
      'bloodPressure': bloodPressure,
      'oxygen': oxygen,
      'sugar': sugar,
      'time': time,
    };
  }

  factory Biometrics.fromJson(Map<String, dynamic> json) {
    return Biometrics(
      measurementDate: json['measurementDate'],
      heartRate: json['heartRate'],
      bloodPressure: json['bloodPressure'] != null ? List<int>.from(json['bloodPressure']) : null,
      oxygen: json['oxygen'],
      sugar: json['sugar'], time: json['time'],
    );
  }

  // @override
  // String toString() {
  //   return 'Biometrics(measurementDate: $measurementDate, heartRate: $heartRate, bloodPressure: $bloodPressure, oxygen: $oxygen, sugar: $sugar)';
  // }
}

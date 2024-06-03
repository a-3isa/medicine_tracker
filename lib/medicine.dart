class Medicine {
  String name;
  String? imagePath;
  String period;
  DateTime time;
  // DateTime creationDay;
  int? alarmId;
  List<Map<DateTime, String>> dates;
  List<Map<bool, String>> checkboxStates;

  Medicine({
    required this.name,
    this.imagePath,
    this.alarmId,
    required this.period,
    required this.time,
    // required this.creationDay,
    List<Map<bool, String>>? checkboxStates,
    List<Map<DateTime, String>>? dates,
  }) : dates = dates ?? [],
        checkboxStates = checkboxStates ?? [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'alarmId':alarmId,
      // 'hours': hours,
      'imagePath': imagePath,
      'checkboxStates': checkboxStates
          .map(
              (map) => map.map((key, value) => MapEntry(key.toString(), value)))
          .toList(),
      // 'days': days,
      'dates': dates
          .map((date) => date.map((key, value) => MapEntry(key.toIso8601String(), value)))
          .toList(),
      'period': period,'time':time.toIso8601String(),
      // 'creationDay': creationDay.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Medicine(name: $name, time: $period, check: $checkboxStates ), dates: $dates';
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      imagePath: json['imagePath'],
      period: json['period'],
      alarmId:json['alarmId'],
      // creationDay: DateTime.parse(json['creationDay']),
      time: DateTime.parse(json['time']),
      checkboxStates: (json['checkboxStates'] as List)
          .map((item) => (item as Map<String, dynamic>)
              .map((key, value) => MapEntry(key == 'true', value as String)))
          .toList(),
      dates: (json['dates'] as List).map((dateMap) =>
          (dateMap as Map<String, dynamic>).map((key, value) =>
              MapEntry(DateTime.parse(key), value as String))).toList(),
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
      bloodPressure: json['bloodPressure'] != null
          ? List<int>.from(json['bloodPressure'])
          : null,
      oxygen: json['oxygen'],
      sugar: json['sugar'],
      time: json['time'],
    );
  }

  @override
  String toString() {
    return 'Biometrics(measurementDate: $measurementDate, heartRate: $heartRate, bloodPressure: $bloodPressure, oxygen: $oxygen, sugar: $sugar)';
  }
}

class Personal {
  String name;
  String age;
  String personCase;

  Personal({
    required this.name,
    required this.age,
    required this.personCase,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'age': age, 'personCase': personCase};
  }

  factory Personal.fromJson(Map<String, dynamic> json) {
    return Personal(
      name: json['name'],
      age: json['age'],
      personCase: json['personCase'],
    );
  }

  @override
  String toString() {
    return 'Personal{name: $name, age: $age, case: $personCase}';
  }
}

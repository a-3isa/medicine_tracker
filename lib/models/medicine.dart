/// Represents a medicine with its details, schedule, and tracking information.
class Medicine {
  final String name;
  final Uint8List? image;
  final String period;
  final DateTime time;
  final int? alarmId;
  final List<Map<DateTime, String>> dates;
  final List<Map<bool, String>> checkboxStates;

  /// Creates a new Medicine instance.
  ///
  /// [name] is the name of the medicine.
  /// [period] is the dosage period (e.g., daily, weekly).
  /// [time] is the scheduled time for taking the medicine.
  /// [image] is an optional image of the medicine.
  /// [alarmId] is the ID of the associated alarm.
  /// [dates] is a list of dates with associated notes.
  /// [checkboxStates] tracks the completion status with notes.
  const Medicine({
    required this.name,
    this.image,
    this.alarmId,
    required this.period,
    required this.time,
    List<Map<bool, String>>? checkboxStates,
    List<Map<DateTime, String>>? dates,
  })  : dates = dates ?? const [],
        checkboxStates = checkboxStates ?? const [];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'alarmId': alarmId,
      'image': image != null ? base64Encode(image!) : null,
      'checkboxStates': checkboxStates
          .map(
              (map) => map.map((key, value) => MapEntry(key.toString(), value)))
          .toList(),
      'dates': dates
          .map((date) =>
              date.map((key, value) => MapEntry(key.toIso8601String(), value)))
          .toList(),
      'period': period,
      'time': time.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Medicine(name: $name, time: $period, check: $checkboxStates ), dates: $dates';
  }

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      name: json['name'],
      image: json['image'] != null ? base64Decode(json['image']) : null,
      period: json['period'],
      alarmId: json['alarmId'],
      time: DateTime.parse(json['time']),
      checkboxStates: (json['checkboxStates'] as List)
          .map((item) => (item as Map<String, dynamic>)
              .map((key, value) => MapEntry(key == 'true', value as String)))
          .toList(),
      dates: (json['dates'] as List)
          .map((dateMap) => (dateMap as Map<String, dynamic>).map(
              (key, value) => MapEntry(DateTime.parse(key), value as String)))
          .toList(),
    );
  }
}

/// Represents biometric measurements for health tracking.
class Biometrics {
  final String measurementDate;
  final String? time;
  final int? heartRate;
  final List<int>? bloodPressure; // List containing systolic and diastolic values
  final double? oxygen;
  final double? sugar;

  /// Creates a new Biometrics instance.
  ///
  /// [measurementDate] is the date of the measurement.
  /// [time] is the optional time of the measurement.
  /// [heartRate] is the heart rate in BPM.
  /// [bloodPressure] is a list of systolic and diastolic values.
  /// [oxygen] is the oxygen saturation level.
  /// [sugar] is the blood sugar level.
  const Biometrics({
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

/// Represents personal information of the user.
class Personal {
  final String name;
  final String age;
  final String personCase;

  /// Creates a new Personal instance.
  ///
  /// [name] is the user's name.
  /// [age] is the user's age.
  /// [personCase] describes the user's medical case.
  const Personal({
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

/// Represents Bipap (Bi-level Positive Airway Pressure) measurements.
class Bipap {
  final DateTime measurementDate;
  final double? bipap;

  /// Creates a new Bipap instance.
  ///
  /// [measurementDate] is the date of the measurement.
  /// [bipap] is the Bipap value.
  const Bipap({
    this.bipap,
    required this.measurementDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'bipap': bipap,
      'measurementDate': measurementDate.toIso8601String(),
    };
  }

  factory Bipap.fromJson(Map<String, dynamic> json) {
    return Bipap(
      bipap: json['bipap'],
      measurementDate: DateTime.parse(json['measurementDate']),
    );
  }

  @override
  String toString() {
    return 'Bipap{bipap: $bipap, measurementDate: $measurementDate}';
  }
}

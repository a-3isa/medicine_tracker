/// Provider for managing medicine, biometrics, bipap, and personal data.
///
/// This provider handles CRUD operations for various health-related data models
/// and notifies listeners when data changes.
class MedicineProvider with ChangeNotifier {
  final List<Medicine> _medicines = [];
  final List<Biometrics> _biometrics = [];
  final List<Bipap> _bipaps = [];
  final List<Personal> _personals = [];

  List<Medicine> get medicines => _medicines;
  List<Biometrics> get biometrics => _biometrics;
  List<Bipap> get bipaps => _bipaps;
  List<Personal> get personals => _personals;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Initializes the provider and loads all data.
  MedicineProvider() {
    loadAllData();
  }

  /// Loads all data from storage asynchronously.
  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _medicines.clear();
      _medicines.addAll(await loadMedicines());
      _biometrics.clear();
      _biometrics.addAll(await loadBiometrics());
      _bipaps.clear();
      _bipaps.addAll(await loadBipap());
      _personals.clear();
      _personals.addAll(await loadPersonal());
    } catch (e) {
      // Handle loading errors appropriately
      debugPrint('Error loading data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new medicine and sorts the list by time.
  Future<void> addMedicine(Medicine medicine) async {
    _medicines.add(medicine);
    _medicines.sort((a, b) {
      if (a.time.hour == b.time.hour) {
        return a.time.minute.compareTo(b.time.minute);
      }
      return a.time.hour.compareTo(b.time.hour);
    });
    try {
      await saveMedicines(_medicines);
    } catch (e) {
      debugPrint('Error saving medicine: $e');
    }
    notifyListeners();
  }

  /// Edits an existing medicine and resorts the list.
  void editMedicine(Medicine medicine) {
    final index = _medicines.indexWhere((m) => m.alarmId == medicine.alarmId);
    if (index != -1) {
      _medicines[index] = medicine;
      _medicines.sort((a, b) {
        if (a.time.hour == b.time.hour) {
          return a.time.minute.compareTo(b.time.minute);
        }
        return a.time.hour.compareTo(b.time.hour);
      });
      try {
        saveMedicines(_medicines);
      } catch (e) {
        debugPrint('Error saving edited medicine: $e');
      }
      notifyListeners();
    }
  }

  /// Updates the checkbox state for a medicine (taken or not).
  void updateCheckbox(Medicine medicine, bool taken) {
    final index = _medicines.indexWhere((m) => m.alarmId == medicine.alarmId);
    if (index != -1) {
      Map<bool, String> mapAtIndex = Map.from(_medicines[index].checkboxStates.last);
      mapAtIndex.remove(mapAtIndex.keys.first);
      mapAtIndex[taken] = taken ? DateFormat('hh:mm a').format(DateTime.now()) : "";
      _medicines[index].checkboxStates.last = mapAtIndex;
      try {
        saveMedicines(_medicines);
      } catch (e) {
        debugPrint('Error updating checkbox: $e');
      }
      notifyListeners();
    }
  }

  /// Deletes a medicine from the list.
  Future<void> deleteMedicine(Medicine medicine) async {
    _medicines.remove(medicine);
    try {
      await saveMedicines(_medicines);
    } catch (e) {
      debugPrint('Error deleting medicine: $e');
    }
    notifyListeners();
  }

  /// Adds new biometrics data.
  Future<void> addBiometrics(Biometrics biometrics) async {
    _biometrics.add(biometrics);
    try {
      await saveBiometrics(_biometrics);
    } catch (e) {
      debugPrint('Error saving biometrics: $e');
    }
    notifyListeners();
  }

  /// Adds new bipap data.
  Future<void> addBipap(Bipap bipap) async {
    _bipaps.add(bipap);
    try {
      await saveBipap(_bipaps);
    } catch (e) {
      debugPrint('Error saving bipap: $e');
    }
    notifyListeners();
  }

  /// Updates personal information.
  Future<void> updatePersonal(Personal personal) async {
    _personals.clear();
    _personals.add(personal);
    try {
      await savePersonal(_personals);
    } catch (e) {
      debugPrint('Error saving personal data: $e');
    }
    notifyListeners();
  }

  // Additional methods for statistics

  /// Gets the total number of medicines.
  int get totalMedicines => _medicines.length;

  /// Gets the number of medicines taken today.
  int get takenToday => _medicines.where((m) => m.checkboxStates.last.keys.first).length;

  /// Gets the number of medicines missed today.
  int get missedToday => _medicines.length - takenToday;
}

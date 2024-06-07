// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:medicine_tracker/classes_handler.dart';
import 'medicine.dart';
import 'package:medicine_tracker/language/language.dart';
import 'package:auto_size_text/auto_size_text.dart';

class MedicineTable extends StatefulWidget {
  final List<Medicine> medicines;
  final void Function(BuildContext, Medicine) onEditPressed; // Updated callback
  final Function(int) onDeletePressed;

  const MedicineTable({
    super.key,
    required this.medicines,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  @override
  _MedicineTableState createState() => _MedicineTableState();
}

class _MedicineTableState extends State<MedicineTable> {
  List<DataColumn> _buildColumns(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double column1Width = screenWidth * 0.15;
    double column2Width = screenWidth * 0.35;
    double column3Width = screenWidth * 0.15;
    double column4Width = screenWidth * 0.15;
    double fontSize = 11;
    return [
      DataColumn(
          label: SizedBox(
        width: column1Width,
        child: Text(
          Languages.of(context)!.medicineColumn,textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize, // Adjust the font size as needed
          ),
        ),
      )),
      DataColumn(
          label: SizedBox(
        width: column2Width,
        child: Text(
          textAlign: TextAlign.center,
          Languages.of(context)!.imageColumn,
          style: TextStyle(
            fontSize: fontSize, // Adjust the font size as needed
          ),
        ),
      )),
      DataColumn(
          label: SizedBox(
        width: column3Width,
        child: Text(
          Languages.of(context)!.timeColumn,textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontSize, // Adjust the font size as needed
          ),
        ),
      )),
      DataColumn(
          label: SizedBox(
        width: column4Width,
        child: Text(
          '${Languages.of(context)!.currentDayName}\n ${Languages.of(context)!.currentDate}',
          style: TextStyle(
            fontSize: fontSize, // Adjust the font size as needed
          ),textAlign: TextAlign.center,
        ),
      )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    List<Medicine>? medicines = widget.medicines;

    return medicines.isNotEmpty ? Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
              dataRowMaxHeight: 0,
              columnSpacing: 0,
              headingRowHeight: 70,
              columns: _buildColumns(context),
              rows: const []),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              dataRowMaxHeight: 100,
              columnSpacing: 0,
              headingRowHeight: 0,
              columns: _buildColumns(context),
              rows: List.generate(widget.medicines.length, (i) {
                Medicine medicine = widget.medicines[i];
                DateTime currentDay = DateTime.now();
                DateTime lastDay = medicine.dates.last.keys.last;

                int deltaDay =
                    currentDay.difference(medicine.dates.last.keys.last).inDays;
                if (deltaDay != 0) {
                  for (int j = 1; j <= deltaDay; j++) {
                    DateTime dateName = lastDay.add(Duration(days: j));
                    String dayName = DateFormat(
                      'EEEE',
                    ).format(dateName);
                    medicine.dates.add({dateName: dayName});
                    medicine.checkboxStates
                        .add({false: ""}); // Default to false for new days
                  }
                  saveMedicines(medicines);
                }
                return DataRow(
                  onLongPress: () {
                    widget.onEditPressed(context, medicine);
                  },
                  cells: [
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.black,
                              width: i <= widget.medicines.length - 2
                                  ? (widget.medicines[i].period ==
                                          widget.medicines[i + 1].period
                                      ? 0
                                      : 5)
                                  : 0, // You can adjust the width as needed
                            ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: screenWidth * 0.15,
                                maxWidth: screenWidth * 0.15,
                                minHeight: 50.0,
                                maxHeight: 150.0,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: AutoSizeText(
                                  medicine.name,textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.black,
                                width: i <= widget.medicines.length - 2
                                    ? (widget.medicines[i].period ==
                                            widget.medicines[i + 1].period
                                        ? 0
                                        : 5)
                                    : 0 // You can adjust the width as needed
                                ),
                          ),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: medicine.image != null
                                ? MemoryImage(medicine.image!)
                                : const AssetImage('assets/1.png')
                                    as ImageProvider,
                          ),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                                color: Colors.black,
                                width: i <= widget.medicines.length - 2
                                    ? (widget.medicines[i].period ==
                                            widget.medicines[i + 1].period
                                        ? 0
                                        : 5)
                                    : 0 // You can adjust the width as needed
                                ),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Padding(
                          padding:
                              const EdgeInsets.only(left: 10, right: 10, top: 10),
                          child: Column(
                            children: [
                              Text(
                                medicine.period,
                                textAlign: TextAlign.center,style: const TextStyle(fontSize: 12.0)
                              ),
                               Padding(
                                 padding: const EdgeInsets.only(top:8.0,bottom: 8),
                                 child: Container(
                                         height: 2,
                                         width: double.infinity,
                                         color: Colors.black,
                                       ),
                               ),
                              Text(DateFormat('hh:mm a').format(medicine.time),style: const TextStyle(fontSize: 12.0))
                            ],
                          ),
                        ),
                      ),
                    ),
                          DataCell(
                            Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.black,
                                      width: i <= widget.medicines.length - 2
                                          ? (widget.medicines[i].period ==
                                                  widget.medicines[i + 1].period
                                              ? 0
                                              : 5)
                                          : 0 // You can adjust the width as needed
                                      ),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Center(
                                child: Checkbox(
                                    value: medicine.checkboxStates.last.keys.first,
                                    onChanged: !medicine.checkboxStates.last.keys.first ? (value) {
                                      setState(() {
                                        // print("************");
                                        Map<bool, String> mapAtIndex =
                                            Map.from(medicine.checkboxStates.last);
                                        mapAtIndex
                                            .remove(mapAtIndex.keys.first);
                                        mapAtIndex[value!] = value == true
                                            ? DateFormat('hh:mm a')
                                                .format(DateTime.now())
                                            : "";
                                        medicine.checkboxStates.last = mapAtIndex;
                                        saveMedicines(medicines);
                                      });
                                    }:null),
                              ),
                            ),
                          )
                  ],
                );
              }),
            ),
          ),
        )
      ],
    ) : const Text("");
  }
}

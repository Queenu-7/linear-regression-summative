import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// The address of the deployed API
const String apiUrl = 'https://crop-yield-api-ai2s.onrender.com/predict';

void main() {
  runApp(const CropYieldApp());
}

class CropYieldApp extends StatelessWidget {
  const CropYieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crop Yield Predictor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF1F8F2),
      ),
      home: const PredictPage(),
    );
  }
}

class FieldInfo {
  final String label;
  final String key;
  final String type; // 'text', 'int' or 'double'
  final String hint;
  final IconData icon;

  const FieldInfo(this.label, this.key, this.type, this.hint, this.icon);
}

const List<FieldInfo> fields = [
  FieldInfo('Country', 'country', 'text', 'e.g. Rwanda', Icons.public),
  FieldInfo('Crop', 'product', 'text', 'e.g. Maize', Icons.eco),
  FieldInfo('Season', 'season_name', 'text', 'e.g. Season A', Icons.wb_sunny),
  FieldInfo(
    'Farming system',
    'crop_production_system',
    'text',
    'e.g. none',
    Icons.agriculture,
  ),
  FieldInfo(
    'Planting month',
    'planting_month',
    'int',
    'e.g. 9 (1-12)',
    Icons.calendar_month,
  ),
  FieldInfo(
    'Harvest month',
    'harvest_month',
    'int',
    'e.g. 1 (1-12)',
    Icons.event,
  ),
  FieldInfo(
    'Harvest year',
    'harvest_year',
    'int',
    'e.g. 2026',
    Icons.date_range,
  ),
  FieldInfo(
    'Area (hectares)',
    'area',
    'double',
    'e.g. 1500',
    Icons.square_foot,
  ),
];

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  State<PredictPage> createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  // one controller per text field, so we can read what the user typed
  final Map<String, TextEditingController> controllers = {
    for (final f in fields) f.key: TextEditingController(),
  };

  // status is 'info', 'success' or 'error'
  String status = 'info';
  String message = 'Fill in the fields and press Predict.';
  String predictedValue = '';
  bool isLoading = false;

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // find the field description from its key
  FieldInfo info(String key) => fields.firstWhere((f) => f.key == key);

  void showResult(String newStatus, String newMessage) {
    setState(() {
      status = newStatus;
      message = newMessage;
    });
  }

  // fills the form with a valid example (handy for demos)
  void fillExample() {
    const example = <String, String>{
      'country': 'Rwanda',
      'product': 'Maize',
      'season_name': 'Season A',
      'crop_production_system': 'none',
      'planting_month': '9',
      'harvest_month': '1',
      'harvest_year': '2026',
      'area': '1500',
    };
    example.forEach((key, value) {
      controllers[key]!.text = value;
    });
    showResult('info', 'Example filled in. Press Predict.');
  }

  void clearAll() {
    for (final c in controllers.values) {
      c.clear();
    }
    showResult('info', 'Fill in the fields and press Predict.');
  }

  // Turns the API's validation error (422) into a readable message
  String readableError(String responseBody) {
    final data = jsonDecode(responseBody);
    final errors = data['detail'] as List;
    final messages = <String>[];

    for (final e in errors) {
      final key = (e['loc'] as List).last.toString();
      final label = fields
          .firstWhere(
            (f) => f.key == key,
            orElse: () => FieldInfo(key, key, 'text', '', Icons.error),
          )
          .label;

      var msg = e['msg'].toString();
      msg = msg.replaceFirst('Value error, ', '');
      msg = msg.split(' Allowed values').first; // drop the very long list

      messages.add('- $label: $msg');
    }
    return messages.join('\n');
  }

  Future<void> predict() async {
    // 1. check for empty fields
    final empty = <String>[];
    for (final f in fields) {
      if (controllers[f.key]!.text.trim().isEmpty) {
        empty.add(f.label);
      }
    }
    if (empty.isNotEmpty) {
      showResult('error', 'Please fill in: ${empty.join(', ')}');
      return;
    }

    // 2. build the JSON body. If a number cannot be parsed, we send the raw
    //    text anyway so the API can reject it with a validation error.
    final body = <String, dynamic>{};
    for (final f in fields) {
      final text = controllers[f.key]!.text.trim();
      if (f.type == 'int') {
        body[f.key] = int.tryParse(text) ?? text;
      } else if (f.type == 'double') {
        body[f.key] = double.tryParse(text) ?? text;
      } else {
        body[f.key] = text;
      }
    }

    setState(() {
      isLoading = true;
    });

    // 3. call the API
    try {
      final response = await http
          .post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        predictedValue = data['predicted_yield_t_per_ha'].toString();
        showResult('success', '');
      } else if (response.statusCode == 422) {
        showResult('error', readableError(response.body));
      } else {
        showResult(
          'error',
          'Server error (${response.statusCode}). Please try again.',
        );
      }
    } catch (e) {
      showResult(
        'error',
        'Could not reach the server. Check your internet connection and try again.',
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  // ---------- small widgets used to build the page ----------

  // one text field
  Widget buildField(String key) {
    final f = info(key);
    return TextField(
      controller: controllers[key],
      // normal keyboard on purpose, so wrong types can be typed
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: f.label,
        hintText: f.hint,
        prefixIcon: Icon(f.icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // a white card with a title that groups some fields
  Widget buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade800),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }

  // green banner at the top of the page
  Widget buildHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade700, Colors.green.shade400],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.grass, color: Colors.white, size: 44),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimate your crop yield',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Enter the details below to get the expected yield in tonnes per hectare.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // the display area: shows info, the prediction, a spinner or an error
  Widget buildResultCard() {
    final bool isSuccess = status == 'success';
    final bool isError = status == 'error';

    final Color mainColor = isError
        ? Colors.red.shade700
        : (isSuccess ? Colors.green.shade800 : Colors.blueGrey.shade700);
    final Color bgColor = isError
        ? Colors.red.shade50
        : (isSuccess ? Colors.green.shade100 : Colors.blueGrey.shade50);

    Widget content;
    if (isLoading) {
      content = const Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Contacting server... the first request can take up to a minute.',
            ),
          ),
        ],
      );
    } else if (isSuccess) {
      content = Column(
        children: [
          Text('Expected yield', style: TextStyle(color: mainColor)),
          Text(
            predictedValue,
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: mainColor,
            ),
          ),
          Text('tonnes per hectare', style: TextStyle(color: mainColor)),
        ],
      );
    } else {
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: mainColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 15, color: mainColor),
            ),
          ),
        ],
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: mainColor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Yield Predictor'),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildHeader(),

                buildSection('Crop and location', Icons.location_on, [
                  buildField('country'),
                  const SizedBox(height: 12),
                  buildField('product'),
                ]),

                buildSection('Season and farming system', Icons.wb_cloudy, [
                  buildField('season_name'),
                  const SizedBox(height: 12),
                  buildField('crop_production_system'),
                ]),

                buildSection('Timing and field size', Icons.schedule, [
                  Row(
                    children: [
                      Expanded(child: buildField('planting_month')),
                      const SizedBox(width: 12),
                      Expanded(child: buildField('harvest_month')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: buildField('harvest_year')),
                      const SizedBox(width: 12),
                      Expanded(child: buildField('area')),
                    ],
                  ),
                ]),

                // the Predict button
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : predict,
                    icon: const Icon(Icons.analytics),
                    label: const Text('Predict'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                // small helper buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: fillExample,
                      icon: const Icon(Icons.auto_fix_high, size: 18),
                      label: const Text('Use example'),
                    ),
                    TextButton.icon(
                      onPressed: clearAll,
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Clear'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // the result / error display area
                buildResultCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/serial_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  String _selectedLanguage = 'English';
  double _chartUpdateInterval = 3.0;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings Section
            _buildSectionHeader('General Settings'),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Dark Mode Toggle
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Enable dark theme for the application'),
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() {
                          _darkMode = value;
                        });
                        // TODO: Implement theme switching
                      },
                    ),
                    const Divider(),
                    // Language Selection
                    ListTile(
                      title: const Text('Language'),
                      subtitle: Text(_selectedLanguage),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        _showLanguageDialog();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data Settings Section
            _buildSectionHeader('Data Settings'),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Chart Update Interval
                    ListTile(
                      title: const Text('Chart Update Interval'),
                      subtitle: Text('${_chartUpdateInterval.toStringAsFixed(1)} seconds'),
                    ),
                    Slider(
                      value: _chartUpdateInterval,
                      min: 1.0,
                      max: 10.0,
                      divisions: 18,
                      label: _chartUpdateInterval.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          _chartUpdateInterval = value;
                        });
                        // TODO: Implement update interval change
                      },
                    ),
                    const Divider(),
                    // Data Export
                    ListTile(
                      title: const Text('Export Data'),
                      subtitle: const Text('Export sensor data to CSV file'),
                      trailing: const Icon(Icons.file_download),
                      onTap: () {
                        // TODO: Implement data export
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Data export not implemented yet')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Device Settings Section
            _buildSectionHeader('Device Settings'),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Connection Settings
                    ListTile(
                      title: const Text('Connection Settings'),
                      subtitle: const Text('Configure device connection parameters'),
                      trailing: const Icon(Icons.settings_input_component),
                      onTap: () {
                        // TODO: Implement connection settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Connection settings not implemented yet')),
                        );
                      },
                    ),
                    const Divider(),
                    // Calibration
                    ListTile(
                      title: const Text('Sensor Calibration'),
                      subtitle: const Text('Calibrate sensors for accurate readings'),
                      trailing: const Icon(Icons.tune),
                      onTap: () {
                        // TODO: Implement sensor calibration
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sensor calibration not implemented yet')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // About Section
            _buildSectionHeader('About'),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Version'),
                      subtitle: const Text('1.0.0'),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Check for Updates'),
                      trailing: const Icon(Icons.system_update),
                      onTap: () {
                        // TODO: Implement update check
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Update check not implemented yet')),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
  
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Select Language'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedLanguage = 'English';
              });
              Navigator.pop(context);
            },
            child: const Text('English'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedLanguage = 'Spanish';
              });
              Navigator.pop(context);
            },
            child: const Text('Spanish'),
          ),
          SimpleDialogOption(
            onPressed: () {
              setState(() {
                _selectedLanguage = 'Portuguese';
              });
              Navigator.pop(context);
            },
            child: const Text('Portuguese'),
          ),
        ],
      ),
    );
  }
}
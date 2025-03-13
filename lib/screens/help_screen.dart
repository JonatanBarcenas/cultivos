import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Help Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Getting Started',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildHelpItem(
                      'Connecting Your Device',
                      'To connect your device, click on the connection icon in the top right corner of the Dashboard screen. Select your device from the list and click "Connect".',
                      Icons.link,
                    ),
                    const Divider(),
                    _buildHelpItem(
                      'Reading Sensor Data',
                      'Once connected, the dashboard will display real-time sensor data from your device. The gauges show current values, while the chart displays historical data.',
                      Icons.show_chart,
                    ),
                    const Divider(),
                    _buildHelpItem(
                      'Adjusting Settings',
                      'Visit the Settings screen to customize the application appearance, data update intervals, and device connection parameters.',
                      Icons.settings,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // FAQ Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildFaqItem(
                      'Why can\'t I see my device in the list?',
                      'Make sure your device is properly connected to your computer and has the correct drivers installed. Click the "Refresh" button to scan for newly connected devices.',
                    ),
                    const Divider(),
                    _buildFaqItem(
                      'What do the gauge colors mean?',
                      'The gauge colors represent different ranges: green for optimal values, orange for borderline values, and red for values that may require attention.',
                    ),
                    const Divider(),
                    _buildFaqItem(
                      'How can I export my sensor data?',
                      'You can export your data to a CSV file from the Settings screen under the "Data Settings" section. Click on "Export Data" to save your current sensor readings.',
                    ),
                    const Divider(),
                    _buildFaqItem(
                      'How often is the data updated?',
                      'By default, data is updated every 3 seconds. You can adjust this interval in the Settings screen under "Data Settings".',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contact Support Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Contact Support',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: const Text('Email Support'),
                      subtitle: const Text('support@cultivosdashboard.com'),
                      onTap: () {
                        // TODO: Implement email support
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Email support not implemented yet')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.chat),
                      title: const Text('Live Chat'),
                      subtitle: const Text('Chat with our support team'),
                      onTap: () {
                        // TODO: Implement live chat
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Live chat not implemented yet')),
                        );
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.help_center),
                      title: const Text('Knowledge Base'),
                      subtitle: const Text('Browse our online documentation'),
                      onTap: () {
                        // TODO: Implement knowledge base link
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Knowledge base not implemented yet')),
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
  
  Widget _buildHelpItem(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.green),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFaqItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(answer),
        ),
      ],
    );
  }
}
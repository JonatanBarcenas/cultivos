import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide CornerStyle, AnimationType;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';

import 'models/sensor_data.dart';
import 'services/serial_service.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: MaterialApp(
        title: 'Cultivos Dashboard',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class DashboardProvider with ChangeNotifier {
  final SerialService _serialService = SerialService();
  List<SensorData> _dataHistory = [];
  SensorData? _latestData;
  bool _isConnected = false;
  
  SerialService get serialService => _serialService;
  List<SensorData> get dataHistory => _dataHistory;
  SensorData? get latestData => _latestData;
  bool get isConnected => _isConnected;
  
  DashboardProvider() {
    _init();
  }
  
  Future<void> _init() async {
    // Listen for data updates
    _serialService.dataStream.listen((data) {
      _latestData = data;
      _dataHistory.add(data);
      
      // Keep only the last 50 data points for the chart
      if (_dataHistory.length > 50) {
        _dataHistory.removeAt(0);
      }
      
      notifyListeners();
    });
    
    // Listen for connection status changes
    _serialService.addListener(() {
      _isConnected = _serialService.isConnected;
      notifyListeners();
    });
    
    // For demo purposes, add sample data
    if (!_isConnected) {
      _addSampleData();
    }
  }
  
  void _addSampleData() {
    // Add some sample data for preview purposes
    _latestData = SensorData.sample();
    _dataHistory.add(_latestData!);
    notifyListeners();
    
    // Simulate data coming in every 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (!_isConnected) {
        final newData = SensorData(
          temperature: 25.0 + (DateTime.now().second % 10),
          humidity: 60.0 + (DateTime.now().second % 15),
          conductivity: 450.0 + (DateTime.now().second % 50),
          ph: 6.5 + (DateTime.now().second % 10) / 10,
          nutrients: 350.0 + (DateTime.now().second % 100),
          fertility: 70.0 + (DateTime.now().second % 20),
          timestamp: DateTime.now(),
        );
        
        _latestData = newData;
        _dataHistory.add(newData);
        
        if (_dataHistory.length > 50) {
          _dataHistory.removeAt(0);
        }
        
        notifyListeners();
        _addSampleData();
      }
    });
  }
  
  Future<void> refreshDevices() async {
    await _serialService.refreshDevices();
    notifyListeners();
  }
  
  Future<bool> connectToDevice(dynamic device) async {
    final result = await _serialService.connect(device);
    notifyListeners();
    return result;
  }
  
  Future<void> disconnect() async {
    await _serialService.disconnect();
    notifyListeners();
  }
  
  @override
  void dispose() {
    _serialService.dispose();
    super.dispose();
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  
  static const List<Widget> _screens = [
    DashboardScreen(title: 'Dashboard'),
    SettingsScreen(),
    HelpScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    return Scaffold(
      body: Row(
        children: [
          // Enhanced Sidebar
          Container(
            width: isDesktop ? 250 : 72,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // App Logo/Title
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: isDesktop
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.eco,
                              size: 32,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Cultivos',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      : Icon(
                          Icons.eco,
                          size: 32,
                          color: colorScheme.primary,
                        ),
                ),
                const Divider(),
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _buildNavItem(
                        icon: Icons.dashboard,
                        label: 'Dashboard',
                        index: 0,
                        isDesktop: isDesktop,
                      ),
                      _buildNavItem(
                        icon: Icons.settings,
                        label: 'Settings',
                        index: 1,
                        isDesktop: isDesktop,
                      ),
                      _buildNavItem(
                        icon: Icons.help,
                        label: 'Help',
                        index: 2,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ),
                ),
                // User profile section at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  child: isDesktop
                      ? Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary,
                              radius: 20,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'User',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Administrator',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : CircleAvatar(
                          backgroundColor: colorScheme.primary,
                          radius: 20,
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            ),
          ),
          // Main content with enhanced styling
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
                child: _screens[_selectedIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isDesktop,
  }) {
    final isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            if (isDesktop) ...[  
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.title});

  final String title;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final latestData = provider.latestData;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.primaryContainer,
        elevation: 0,
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              provider.isConnected ? Icons.link : Icons.link_off,
              color: provider.isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _showConnectionDialog,
            tooltip: 'Connection Settings',
          ),
        ],
      ),
      body: latestData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.sensors_off,
                    size: 64,
                    color: colorScheme.primary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No data available',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Connect to a device to start monitoring'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showConnectionDialog,
                    icon: const Icon(Icons.link),
                    label: const Text('Connect Device'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status card with enhanced styling
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primaryContainer,
                              colorScheme.primaryContainer.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: provider.isConnected 
                                        ? Colors.green.withOpacity(0.2) 
                                        : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    provider.isConnected ? Icons.check_circle : Icons.error,
                                    color: provider.isConnected ? Colors.green : Colors.red,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      provider.isConnected ? 'Connected' : 'Disconnected',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last Update: ${DateFormat('HH:mm:ss').format(latestData.timestamp)}',
                                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _showConnectionDialog,
                              icon: Icon(provider.isConnected ? Icons.link_off : Icons.link),
                              label: Text(provider.isConnected ? 'Disconnect' : 'Connect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: provider.isConnected 
                                    ? colorScheme.errorContainer 
                                    : colorScheme.primaryContainer,
                                foregroundColor: provider.isConnected 
                                    ? colorScheme.error 
                                    : colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Dashboard title
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        'Sensor Readings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    
                    // Gauges in a grid layout for better responsiveness
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildGauge(
                          'Temperature', 
                          latestData.temperature, 
                          0, 50, 
                          '°C',
                          Colors.red,
                        ),
                        _buildGauge(
                          'Humidity', 
                          latestData.humidity, 
                          0, 100, 
                          '%',
                          Colors.blue,
                        ),
                        _buildGauge(
                          'pH', 
                          latestData.ph, 
                          0, 14, 
                          '',
                          Colors.purple,
                        ),
                        _buildGauge(
                          'Conductivity', 
                          latestData.conductivity, 
                          0, 1000, 
                          'μS/cm',
                          Colors.amber,
                        ),
                        _buildGauge(
                          'Nutrients', 
                          latestData.nutrients, 
                          0, 1000, 
                          'ppm',
                          Colors.green,
                        ),
                        _buildGauge(
                          'Fertility', 
                          latestData.fertility, 
                          0, 100, 
                          '%',
                          Colors.brown,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Historical data chart with enhanced styling
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Historical Data',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: 'Refresh Data',
                                  onPressed: () {
                                    // Refresh data
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                            const Divider(),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 300,
                              child: _buildHistoricalChart(provider.dataHistory),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildGauge(String title, double value, double min, double max, String unit, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedValue = value.toStringAsFixed(1);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              colorScheme.surfaceVariant.withOpacity(0.3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$formattedValue $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: SfRadialGauge(
                axes: <RadialAxis>[
                  RadialAxis(
                    minimum: min,
                    maximum: max,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      cornerStyle: CornerStyle.bothCurve,
                      color: colorScheme.surfaceVariant,
                      thicknessUnit: GaugeSizeUnit.factor,
                    ),
                    ranges: <GaugeRange>[
                      GaugeRange(
                        startValue: min, 
                        endValue: max * 0.33, 
                        color: Colors.green.withOpacity(0.7),
                        startWidth: 0.2,
                        endWidth: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: max * 0.33, 
                        endValue: max * 0.66, 
                        color: Colors.orange.withOpacity(0.7),
                        startWidth: 0.2,
                        endWidth: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                      GaugeRange(
                        startValue: max * 0.66, 
                        endValue: max, 
                        color: Colors.red.withOpacity(0.7),
                        startWidth: 0.2,
                        endWidth: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                      ),
                    ],
                    pointers: <GaugePointer>[
                      NeedlePointer(
                        value: value, 
                        enableAnimation: true, 
                        animationType: AnimationType.ease,
                        needleColor: color,
                        needleLength: 0.6,
                        needleStartWidth: 1,
                        needleEndWidth: 5,
                        knobStyle: KnobStyle(
                          knobRadius: 0.08,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: color,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(getIconForSensor(title), color: color, size: 16),
                            const SizedBox(height: 2),
                            Text(
                              getStatusForValue(title, value),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: getColorForStatus(title, value),
                              ),
                            ),
                          ],
                        ),
                        angle: 90,
                        positionFactor: 0.8,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData getIconForSensor(String sensorType) {
    switch (sensorType) {
      case 'Temperature':
        return Icons.thermostat;
      case 'Humidity':
        return Icons.water_drop;
      case 'pH':
        return Icons.science;
      case 'Conductivity':
        return Icons.bolt;
      case 'Nutrients':
        return Icons.grass;
      case 'Fertility':
        return Icons.spa;
      default:
        return Icons.sensors;
    }
  }
  
  String getStatusForValue(String sensorType, double value) {
    switch (sensorType) {
      case 'Temperature':
        if (value < 15) return 'Low';
        if (value > 35) return 'High';
        return 'Optimal';
      case 'Humidity':
        if (value < 40) return 'Dry';
        if (value > 80) return 'Humid';
        return 'Optimal';
      case 'pH':
        if (value < 5.5) return 'Acidic';
        if (value > 7.5) return 'Alkaline';
        return 'Optimal';
      case 'Conductivity':
        if (value < 200) return 'Low';
        if (value > 800) return 'High';
        return 'Optimal';
      case 'Nutrients':
        if (value < 200) return 'Low';
        if (value > 800) return 'High';
        return 'Optimal';
      case 'Fertility':
        if (value < 30) return 'Low';
        if (value > 80) return 'High';
        return 'Optimal';
      default:
        return 'Normal';
    }
  }
  
  Color getColorForStatus(String sensorType, double value) {
    switch (getStatusForValue(sensorType, value)) {
      case 'Low':
      case 'Dry':
      case 'Acidic':
        return Colors.blue;
      case 'High':
      case 'Humid':
      case 'Alkaline':
        return Colors.red;
      case 'Optimal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildHistoricalChart(List<SensorData> dataHistory) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return SfCartesianChart(
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.all(8),
      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('HH:mm:ss'),
        intervalType: DateTimeIntervalType.seconds,
        majorGridLines: const MajorGridLines(width: 0.3, dashArray: [5, 5]),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
      ),
      primaryYAxis: NumericAxis(
        title: AxisTitle(
          text: 'Values',
          textStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
        ),
        majorGridLines: const MajorGridLines(width: 0.3, dashArray: [5, 5]),
        axisLine: const AxisLine(width: 0),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
      ),
      legend: Legend(
        isVisible: true,
        position: LegendPosition.bottom,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: TextStyle(color: colorScheme.onSurface, fontSize: 12),
      ),
      tooltipBehavior: TooltipBehavior(
        enable: true,
        duration: 2000,
        animationDuration: 500,
        canShowMarker: true,
        format: 'point.x : point.y',
        header: '',
      ),
      crosshairBehavior: CrosshairBehavior(
        enable: true,
        lineType: CrosshairLineType.both,
        lineDashArray: <double>[5, 5],
        lineWidth: 1,
        lineColor: colorScheme.primary.withOpacity(0.5),
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePinching: true,
        enablePanning: true,
        enableDoubleTapZooming: true,
        zoomMode: ZoomMode.x,
      ),
      series: <CartesianSeries<SensorData, DateTime>>[
        // Temperature series with enhanced styling
        LineSeries<SensorData, DateTime>(
          name: 'Temperature',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.temperature,
          color: Colors.red,
          width: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: Colors.red,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        ),
        // Humidity series with enhanced styling
        LineSeries<SensorData, DateTime>(
          name: 'Humidity',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.humidity,
          color: Colors.blue,
          width: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: Colors.blue,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        ),
        // pH series with enhanced styling
        LineSeries<SensorData, DateTime>(
          name: 'pH',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.ph,
          color: Colors.purple,
          width: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.circle,
            borderWidth: 2,
            borderColor: Colors.purple,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        ),
        // Conductivity series
        LineSeries<SensorData, DateTime>(
          name: 'Conductivity',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.conductivity / 20, // Scaled for visibility
          color: Colors.amber,
          width: 2.5,
          dashArray: <double>[5, 3],
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.diamond,
            borderWidth: 2,
            borderColor: Colors.amber,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        ),
      ],
    );
  }
  
  void _showConnectionDialog() {
    final provider = Provider.of<DashboardProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connection Settings'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              width: 300,
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Status: ${provider.isConnected ? "Connected" : "Disconnected"}'),
                  const SizedBox(height: 16),
                  const Text('Available Devices:'),
                  const SizedBox(height: 8),
                  Expanded(
                    child: provider.serialService.devices.isEmpty
                        ? const Center(child: Text('No devices found'))
                        : ListView.builder(
                            itemCount: provider.serialService.devices.length,
                            itemBuilder: (context, index) {
                              final device = provider.serialService.devices[index];
                              return ListTile(
                                title: Text(device.productName ?? 'Unknown Device'),
                                subtitle: Text('VID: ${device.vid}, PID: ${device.pid}'),
                                trailing: ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await provider.connectToDevice(device);
                                  },
                                  child: const Text('Connect'),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await provider.refreshDevices();
              setState(() {});
            },
            child: const Text('Refresh'),
          ),
          if (provider.isConnected)
            TextButton(
              onPressed: () async {
                await provider.disconnect();
                Navigator.pop(context);
              },
              child: const Text('Disconnect'),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
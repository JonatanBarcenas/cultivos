import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' hide CornerStyle, AnimationType;
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';


import 'models/sensor_data.dart';
import 'services/serial_service.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/gardens_screen.dart';
import 'screens/diagnostic_screen.dart';
import 'screens/usb_diagnostic_screen.dart';

void main() {
  // Inicializar sqflite_ffi para Windows
  sqfliteFfiInit();
  // Establecer databaseFactory para usar con sqflite_common_ffi
  databaseFactory = databaseFactoryFfi;
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DashboardProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'GrowSense',
        theme: ThemeData(
          colorScheme: ColorScheme(
            primary: const Color(0xFF74B43F), // Verde GrowSense
            onPrimary: Colors.white,
            primaryContainer: const Color(0xFF74B43F),
            onPrimaryContainer: Colors.white,
            secondary: const Color(0xFF4B8B1D), // Verde oscuro GrowSense
            onSecondary: Colors.white,
            secondaryContainer: const Color(0xFF4B8B1D),
            onSecondaryContainer: Colors.white,
            tertiary: const Color(0xFFFFA000), // Acento amarillo/naranja
            onTertiary: Colors.white,
            tertiaryContainer: const Color(0xFFFFE082),
            onTertiaryContainer: const Color(0xFFE65100),
            error: Colors.red,
            onError: Colors.white,
            errorContainer: const Color(0xFFFFCDD2),
            onErrorContainer: const Color(0xFFB71C1C),
            background: const Color(0xFFFFFFFF), // Blanco de fondo
            onBackground: const Color(0xFF333333), // Gris oscuro para texto
            surface: const Color(0xFFFFFFFF),
            onSurface: const Color(0xFF333333),
            surfaceVariant: const Color(0xFFF5F5F5),
            onSurfaceVariant: const Color(0xFF666666),
            outline: const Color(0xFFBDBDBD),
            shadow: const Color(0x40000000),
            inverseSurface: const Color(0xFF333333),
            onInverseSurface: const Color(0xFFFFFFFF),
            inversePrimary: const Color(0xFFA5D6A7),
            surfaceTint: const Color(0xFF2E7D32),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF333333)),
            bodyMedium: TextStyle(color: Color(0xFF333333)),
            titleLarge: TextStyle(color: Color(0xFF333333)),
            titleMedium: TextStyle(color: Color(0xFF333333)),
            titleSmall: TextStyle(color: Color(0xFF333333)),
          ),
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
      // Only process and add data if it's not a zero value or if we're connected
      if (_serialService.isConnected || 
          (data.temperature > 0 || data.humidity > 0 || 
           data.conductivity > 0 || data.ph > 0 || 
           data.nutrients > 0 || data.fertility > 0)) {
        _latestData = data;
        _dataHistory.add(data);
        
        // Keep only the last 50 data points for the chart
        if (_dataHistory.length > 50) {
          _dataHistory.removeAt(0);
        }
        
        notifyListeners();
      }
    });
    
    // Listen for connection status changes
    _serialService.addListener(() {
      _isConnected = _serialService.isConnected;
      notifyListeners();
    });
    
    // No longer adding sample data when disconnected to prevent graph disorder
    // if (!_isConnected) {
    //   _addSampleData();
    // }
  }
  
  void _addSampleData() {
    // Add zero values when no device is connected
    _latestData = SensorData.zero();
    _dataHistory.add(_latestData!);
    notifyListeners();
    
    // Check connection status every 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!_isConnected) {
        // Use zero values when no device is connected
        final newData = SensorData.zero();
        
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  static const List<Widget> _screens = [
    DashboardScreen(title: 'Dashboard'),
    ReportsScreen(),
    GardensScreen(),
    DiagnosticScreen()
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Close drawer on mobile after selection
    if (MediaQuery.of(context).size.width < 800) {
      _scaffoldKey.currentState?.closeDrawer();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    // Build the sidebar content that will be used in both desktop and mobile views
    Widget sidebarContent = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF74B43F), // Verde GrowSense
            const Color(0xFF4B8B1D), // Verde oscuro GrowSense
          ],
          stops: const [0.1, 1.0],
        ),
      ),
      child: Column(
        children: [
          // App Logo/Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.eco,
                  size: 32,
                  color: Colors.white,
                ),
                if (isDesktop || MediaQuery.of(context).size.width < 800) ...[  // Always show text in drawer
                  const SizedBox(width: 12),
                  Text(
                    'GrowSense',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          // Navigation Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  icon: Icons.dashboard,
                  label: 'Monitoreo',
                  index: 0,
                  isDesktop: isDesktop || MediaQuery.of(context).size.width < 800,  // Show text in drawer
                ),
                _buildNavItem(
                  icon: Icons.assessment,
                  label: 'Reportes',
                  index: 1,
                  isDesktop: isDesktop || MediaQuery.of(context).size.width < 800,  // Show text in drawer
                ),
                _buildNavItem(
                  icon: Icons.eco,
                  label: 'Huertas',
                  index: 2,
                  isDesktop: isDesktop || MediaQuery.of(context).size.width < 800,  // Show text in drawer
                ),
                _buildNavItem(
                  icon: Icons.analytics,
                  label: 'Diagnóstico',
                  index: 3,
                  isDesktop: isDesktop || MediaQuery.of(context).size.width < 800,  // Show text in drawer
                ),
              ],
            ),
          ),
          
        ],
      ),
    );
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: !isDesktop ? AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: colorScheme.primary),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          _screens[_selectedIndex].toString().replaceAll('Screen', ''),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ) : null,
      // Use drawer for mobile and sidebar for desktop
      drawer: !isDesktop ? Drawer(
        elevation: 2,
        child: sidebarContent,
      ) : null,
      body: Row(
        children: [
          // Show sidebar only on desktop
          if (isDesktop)
            Container(
              width: 250,
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
              child: sidebarContent,
            ),
          // Main content with enhanced styling
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: isDesktop ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ) : null,
              ),
              child: ClipRRect(
                borderRadius: isDesktop ? const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ) : BorderRadius.zero,
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
    return InkWell(
      onTap: () => _onItemTapped(index),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFE0E0E0) : Colors.white,
            ),
            if (isDesktop) ...[  
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFFE0E0E0) : Colors.white,
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.background,
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
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final provider = Provider.of<DashboardProvider>(context, listen: false);
              await provider.refreshDevices();
              if (provider.serialService.devices.isNotEmpty) {
                await provider.connectToDevice(provider.serialService.devices[0]);
              }
            },
            tooltip: 'Refresh USB Devices',
          ),
          IconButton(
            icon: const Icon(Icons.usb),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const UsbDiagnosticScreen(),
                ),
              );
            },
            tooltip: 'USB Diagnostic',
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
                  // Connect button removed since connection is automatic
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
                        child: MediaQuery.of(context).size.width > 600
                          // Desktop/tablet layout
                          ? Row(
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
                              ],
                            )
                          // Mobile layout
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
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
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Connection button removed since connection is automatic
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
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 3 : 
                                     MediaQuery.of(context).size.width > 600 ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.2 : 1.5,
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
                    
                  ],
                ),
              ),
            ),
    );
  }
  
  Widget _buildGauge(String title, double value, double min, double max, String unit, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final formattedValue = value.toStringAsFixed(1);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
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
                Flexible(
                  child: Row(
                    children: [
                      Icon(getIconForSensor(title), color: color, size: isSmallScreen ? 14 : 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$formattedValue $unit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallScreen ? 12 : 16),
            SizedBox(
              height: isSmallScreen ? 120 : 150,
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
                        needleStartWidth: isSmallScreen ? 0.5 : 1,
                        needleEndWidth: isSmallScreen ? 4 : 5,
                        knobStyle: KnobStyle(
                          knobRadius: isSmallScreen ? 0.07 : 0.08,
                          sizeUnit: GaugeSizeUnit.factor,
                          color: color,
                        ),
                      ),
                    ],
                    annotations: <GaugeAnnotation>[
                      GaugeAnnotation(
                        widget: Container(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                          decoration: BoxDecoration(
                            color: getColorForStatus(title, value).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            getStatusForValue(title, value),
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              fontWeight: FontWeight.bold,
                              color: getColorForStatus(title, value),
                            ),
                          ),
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
  
  // Track the currently selected measurement type for the chart
  String _selectedMeasurement = 'Temperature';
  
  Widget _buildHistoricalChart(List<SensorData> dataHistory) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Column(
      children: [
        // Measurement type selector
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMeasurementChip('Temperature', Colors.red),
                _buildMeasurementChip('Humidity', Colors.blue),
                _buildMeasurementChip('pH', Colors.purple),
                _buildMeasurementChip('Conductivity', Colors.amber),
                _buildMeasurementChip('Nutrients', Colors.green),
                _buildMeasurementChip('Fertility', Colors.orange),
              ],
            ),
          ),
        ),
        
        // Chart for the selected measurement
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.all(isSmallScreen ? 4 : 8),
            primaryXAxis: DateTimeAxis(
              dateFormat: DateFormat('HH:mm:ss'),
              intervalType: DateTimeIntervalType.seconds,
              majorGridLines: const MajorGridLines(width: 0.3, dashArray: [5, 5]),
              axisLine: const AxisLine(width: 0),
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: isSmallScreen ? 8 : 10),
              labelIntersectAction: AxisLabelIntersectAction.hide,
              maximumLabels: isSmallScreen ? 3 : 5,
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(
                text: _getYAxisTitle(_selectedMeasurement),
                textStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: isSmallScreen ? 10 : 12),
              ),
              majorGridLines: const MajorGridLines(width: 0.3, dashArray: [5, 5]),
              axisLine: const AxisLine(width: 0),
              labelStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: isSmallScreen ? 8 : 10),
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
              // Only show the selected measurement type
              _getSeriesForMeasurement(_selectedMeasurement, dataHistory),
            ],
          ),
        ),
      ],
    );
  }
  
  // Helper method to build a selectable chip for each measurement type
  Widget _buildMeasurementChip(String measurementType, Color color) {
    final isSelected = _selectedMeasurement == measurementType;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        selected: isSelected,
        label: Text(measurementType),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: colorScheme.surface,
        selectedColor: color,
        checkmarkColor: Colors.white,
        elevation: isSelected ? 3 : 1,
        onSelected: (selected) {
          setState(() {
            _selectedMeasurement = measurementType;
          });
        },
      ),
    );
  }
  
  // Helper method to get the appropriate Y-axis title based on measurement type
  String _getYAxisTitle(String measurementType) {
    switch (measurementType) {
      case 'Temperature':
        return 'Temperature (°C)';
      case 'Humidity':
        return 'Humidity (%)';
      case 'pH':
        return 'pH';
      case 'Conductivity':
        return 'Conductivity (μS/cm)';
      case 'Nutrients':
        return 'Nutrients (ppm)';
      case 'Fertility':
        return 'Fertility (%)';
      default:
        return 'Value';
    }
  }
  
  // Helper method to get the appropriate series for the selected measurement type
  LineSeries<SensorData, DateTime> _getSeriesForMeasurement(String measurementType, List<SensorData> dataHistory) {
    switch (measurementType) {
      case 'Temperature':
        return LineSeries<SensorData, DateTime>(
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
        );
      case 'Humidity':
        return LineSeries<SensorData, DateTime>(
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
        );
      case 'pH':
        return LineSeries<SensorData, DateTime>(
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
        );
      case 'Conductivity':
        return LineSeries<SensorData, DateTime>(
          name: 'Conductivity',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.conductivity,
          color: Colors.amber,
          width: 2.5,
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
        );
      case 'Nutrients':
        return LineSeries<SensorData, DateTime>(
          name: 'Nutrients',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.nutrients,
          color: Colors.green,
          width: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.triangle,
            borderWidth: 2,
            borderColor: Colors.green,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        );
      case 'Fertility':
        return LineSeries<SensorData, DateTime>(
          name: 'Fertility',
          dataSource: dataHistory,
          xValueMapper: (SensorData data, _) => data.timestamp,
          yValueMapper: (SensorData data, _) => data.fertility,
          color: Colors.orange,
          width: 2.5,
          markerSettings: const MarkerSettings(
            isVisible: true,
            height: 6,
            width: 6,
            shape: DataMarkerType.pentagon,
            borderWidth: 2,
            borderColor: Colors.orange,
          ),
          animationDuration: 1500,
          enableTooltip: true,
        );
      default:
        return LineSeries<SensorData, DateTime>(
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
        );
    }
  }
  
  void _showConnectionDialog() {
    // This method is now empty as we're removing manual connection functionality
    // The connection happens automatically when the app starts
  }
}
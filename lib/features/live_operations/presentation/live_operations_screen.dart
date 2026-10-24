import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/theme/admin_theme.dart';

class LiveOperationsScreen extends StatefulWidget {
  const LiveOperationsScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<LiveOperationsScreen> createState() => _LiveOperationsScreenState();
}

class _LiveOperationsScreenState extends State<LiveOperationsScreen> {
  Position? _position;
  bool _loadingLocation = false;
  String? _locationMessage;

  Future<void> _getMyLocation() async {
    setState(() {
      _loadingLocation = true;
      _locationMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationMessage('Location services are off. Turn them on and try again.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        _setLocationMessage('Location permission was denied. Allow it to use My Location.');
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _setLocationMessage('Location permission is blocked. Enable it in your device/browser settings.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      setState(() {
        _position = position;
        _locationMessage = 'Location fetched on this device. It has not been uploaded or shared.';
      });
    } catch (_) {
      _setLocationMessage(
        'Could not get your location. Check browser/device permission and try again.',
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  void _setLocationMessage(String message) {
    if (!mounted) return;
    setState(() => _locationMessage = message);
  }

  @override
  Widget build(BuildContext context) {
    final position = _position;
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final padding = compact ? 16.0 : 28.0;
          return ListView(
            shrinkWrap: widget.embedded,
            physics: widget.embedded ? const NeverScrollableScrollPhysics() : null,
            padding: EdgeInsets.all(padding),
            children: [
              Text(
                'Live Operations',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AdminTheme.primaryText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Monitor walk workflows and location readiness from one workspace.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6D665F),
                    ),
              ),
              const SizedBox(height: 22),
              Container(
                padding: EdgeInsets.all(compact ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF0E2), Color(0xFFFFFAF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFFD2AD)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: AdminTheme.brandOrange, size: 25),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Trusted data only', style: TextStyle(fontWeight: FontWeight.w800)),
                          SizedBox(height: 5),
                          Text(
                            'Live booking and walker feeds are not connected yet. No fake counts or unverified walker positions will be shown.',
                            style: TextStyle(height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _OperationsCard(
                icon: Icons.my_location_outlined,
                title: 'My Location',
                subtitle: 'Check this device/browser location with your permission.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _loadingLocation ? null : _getMyLocation,
                      icon: _loadingLocation
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                      label: Text(_loadingLocation ? 'Getting location…' : 'My Location'),
                    ),
                    if (position != null) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _CoordinateChip(
                            label: 'Latitude',
                            value: position.latitude.toStringAsFixed(6),
                          ),
                          _CoordinateChip(
                            label: 'Longitude',
                            value: position.longitude.toStringAsFixed(6),
                          ),
                          _CoordinateChip(
                            label: 'Accuracy',
                            value: 'about ${position.accuracy.toStringAsFixed(0)} m',
                          ),
                        ],
                      ),
                    ],
                    if (_locationMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(_locationMessage!),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Privacy: coordinates stay on this screen and are not uploaded or shared.',
                      style: TextStyle(color: Color(0xFF6D665F), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OperationsCard(
                icon: Icons.radar_outlined,
                title: 'Possible Walker Nearby',
                subtitle: 'Proximity is a signal to review, not proof of presence.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.hourglass_empty, color: AdminTheme.brandOrange, size: 17),
                          SizedBox(width: 7),
                          Text('Not checked', style: TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Not connected yet. This indicator will only be enabled after walker-location data, consent, freshness limits and access rules are verified. Until then, nearby status is unknown.',
                      style: TextStyle(height: 1.45),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _OperationsCard(
                icon: Icons.route_outlined,
                title: 'Live walk feed',
                subtitle: 'Booking and walker activity',
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF817970)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Feed connection pending. Live walk actions will be added only after backend permissions and state transitions are verified.',
                        style: TextStyle(height: 1.45),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OperationsCard extends StatelessWidget {
  const _OperationsCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0E2),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AdminTheme.brandOrange, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AdminTheme.primaryText,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6D665F),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _CoordinateChip extends StatelessWidget {
  const _CoordinateChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6D665F), fontSize: 12)),
          const SizedBox(height: 4),
          SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

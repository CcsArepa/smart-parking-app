import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/bounce_button.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../data/datasources/mock/mock_parking_source.dart';
import '../../../domain/entities/parking_lot.dart';
import '../../providers/parking_providers.dart';
import '../../providers/session_controller.dart';
import '../zone_detail/widgets/parking_lot_card.dart';

/// Mapa interactivo del campus con los estacionamientos en vivo.
///
/// ¿Por qué un mapa real (OpenStreetMap) y no una imagen del plano?
/// - No existe un mapa oficial público de estacionamientos de la UDLAP.
/// - Una imagen fija no se puede acercar bien y no muestra datos en vivo.
/// - Aquí cada pin tiene el **color y número de plazas actuales**, así el
///   usuario elige a dónde ir de un vistazo (reconocimiento espacial).
///
/// Requiere internet para descargar el mapa. Los mosaicos son de
/// OpenStreetMap (© colaboradores de OpenStreetMap, licencia ODbL).
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _campus = LatLng(MockParkingSource.campusLat, MockParkingSource.campusLng);
  static const double _initialZoom = 16.4;

  final _map = MapController();

  void _zoomBy(double delta) {
    final camera = _map.camera;
    _map.move(camera.center, (camera.zoom + delta).clamp(14.0, 19.0));
  }

  void _recenter() => _map.move(_campus, _initialZoom);

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lots = ref.watch(parkingLotsProvider).value?.values
            .where((l) => l.hasLocation)
            .toList() ??
        const <ParkingLot>[];
    final sessionLot = ref.watch(activeSessionProvider).value?.lotId;

    return AppScaffold(
      tab: AppTab.map,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radius + 4),
            border: Border.fromBorderSide(AppTheme.outline),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius + 2),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _map,
                  options: const MapOptions(
                    initialCenter: _campus,
                    initialZoom: _initialZoom,
                    minZoom: 14,
                    maxZoom: 19,
                    backgroundColor: Color(0xFFE8EFE9),
                    // Sin rotación: un mapa girado desorienta a la mayoría.
                    interactionOptions: InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'mx.udlap.udlap_parking',
                    ),
                    MarkerLayer(
                      markers: [
                        for (final lot in lots)
                          Marker(
                            point: LatLng(lot.latitude!, lot.longitude!),
                            width: 84,
                            height: 70,
                            alignment: Alignment.topCenter,
                            child: _LotMarker(
                              lot: lot,
                              isMine: lot.id == sessionLot,
                              onTap: () => _showLotSheet(lot),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                // Atribución obligatoria de OpenStreetMap (licencia ODbL).
                Positioned(
                  left: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    color: const Color(0xCCFFFFFF),
                    child: const Text(
                      '© OpenStreetMap',
                      style: TextStyle(fontSize: 11, color: AppColors.black),
                    ),
                  ),
                ),
                const Positioned(top: 10, left: 10, right: 10, child: _Legend()),
                Positioned(
                  right: 10,
                  bottom: 34,
                  child: Column(
                    children: [
                      CircleIconButton(
                        icon: Icons.add_rounded,
                        tooltip: 'Acercar',
                        size: 48,
                        background: AppColors.white,
                        onPressed: () => _zoomBy(1),
                      ),
                      const SizedBox(height: 10),
                      CircleIconButton(
                        icon: Icons.remove_rounded,
                        tooltip: 'Alejar',
                        size: 48,
                        background: AppColors.white,
                        onPressed: () => _zoomBy(-1),
                      ),
                      const SizedBox(height: 10),
                      CircleIconButton(
                        icon: Icons.my_location_rounded,
                        tooltip: 'Centrar en el campus',
                        size: 48,
                        onPressed: _recenter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLotSheet(ParkingLot lot) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => _LotSheet(lotId: lot.id),
    );
  }
}

/// Pin del mapa: etiqueta "E10 · 17" sobre un pin del color de semáforo.
class _LotMarker extends StatelessWidget {
  const _LotMarker({required this.lot, required this.isMine, required this.onTap});

  final ParkingLot lot;
  final bool isMine;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AvailabilityBadge.colorFor(lot);
    final full = lot.availability == Availability.full;

    return BounceButton(
      onPressed: onTap,
      pressedScale: 0.85,
      semanticLabel: 'Estacionamiento ${lot.name}, ${AvailabilityBadge.spokenText(lot)}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isMine ? AppColors.black : color, width: isMine ? 2.5 : 2),
              boxShadow: AppTheme.shadow(blur: 4, dy: 2, alpha: 0.25),
            ),
            child: FittedBox(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isMine) ...[
                    const Icon(Icons.directions_car_rounded, size: 14),
                    const SizedBox(width: 3),
                  ],
                  Text(lot.name, style: AppTextStyles.numbers(context, size: 13)),
                  const SizedBox(width: 4),
                  Text(
                    full ? 'LLENO' : '${lot.availableSpots}',
                    style: AppTextStyles.numbers(context, size: 13, color: color),
                  ),
                ],
              ),
            ),
          ),
          Icon(Icons.location_on, size: 38, color: color, shadows: const [
            Shadow(color: Color(0x55000000), blurRadius: 4, offset: Offset(0, 2)),
          ]),
        ],
      ),
    );
  }
}

/// Leyenda del semáforo (color + palabra: nunca sólo color).
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_on, color: c, size: 18),
            Text(label, style: AppTextStyles.numbers(context, size: 13, weight: FontWeight.w700)),
          ],
        );

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.black, width: 1.5),
        ),
        child: Wrap(
          spacing: 10,
          children: [
            item(AppColors.availableText, 'Con lugar'),
            item(AppColors.lowText, 'Pocos'),
            item(AppColors.fullText, 'Lleno'),
          ],
        ),
      ),
    );
  }
}

/// Detalle de un estacionamiento al tocar su pin.
class _LotSheet extends ConsumerWidget {
  const _LotSheet({required this.lotId});
  final String lotId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final lot = ref.watch(parkingLotProvider(lotId));
    final zone = ref.watch(zoneForLotProvider(lotId));
    if (lot == null) return const SizedBox(height: 120);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.orange, size: 40),
                Text(lot.name, style: AppTextStyles.numbers(context, size: 34)),
                const Spacer(),
                AvailabilityBadge(lot: lot, compact: true),
              ],
            ),
            if (zone != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Cerca de ${zone.name} · capacidad ${lot.capacity}',
                    style: textTheme.bodyMedium!.copyWith(fontSize: 16)),
              ),
            const SizedBox(height: 16),
            if (zone != null)
              BounceButton(
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  navigator.pushNamed(
                    AppRoutes.report,
                    arguments: ReportArgs(zone: zone, lotId: lot.id),
                  );
                },
                semanticLabel: 'Ir a reportar en ${lot.name}',
                rippleRadius: BorderRadius.circular(AppTheme.radius),
                actionDelay: const Duration(milliseconds: 140),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.fromBorderSide(AppTheme.outline),
                  ),
                  child: Text('Voy para allá', style: textTheme.labelLarge!.copyWith(fontSize: 20)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

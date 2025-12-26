import 'package:digit_ui_components/enum/app_enums.dart';
import 'package:digit_ui_components/widgets/atoms/digit_info_card.dart';
import 'package:flutter/material.dart';

import '../../action_handler/action_config.dart';
import '../../blocs/flow_crud_bloc.dart';
import '../../utils/conditional_evaluator.dart';
import '../../utils/interpolation.dart';
import '../../widget_registry.dart';
import '../flow_widget_interface.dart';
import '../localization_context.dart';

class InfoCardWidget implements FlowWidget {
  @override
  String get format => 'infoCard';

  @override
  Widget build(
    Map<String, dynamic> json,
    BuildContext context,
    void Function(ActionConfig) onAction,
  ) {
    final crudCtx = CrudItemContext.of(context);
    final items = crudCtx?.stateData?.rawState ?? [];
    final modelMap = crudCtx?.stateData?.modelMap ?? {};

    // Get screenKey and navigation params for visibility evaluation
    final screenKey = crudCtx?.screenKey ?? getScreenKeyFromArgs(context);
    final navigationParams = screenKey != null
        ? FlowCrudStateRegistry().getNavigationParams(screenKey) ?? {}
        : <String, dynamic>{};
    final formData = screenKey != null
        ? FlowCrudStateRegistry().get(screenKey)?.formData ?? {}
        : <String, dynamic>{};

    // Create evaluation context that includes modelMap for named entity access
    final evalContext = {
      'item': crudCtx?.item,
      'contextData': crudCtx?.stateData?.rawState ?? {},
      'navigation': navigationParams,
      ...modelMap,
      // Include modelMap so {{stock}}, {{productVariant}} etc. can be resolved
      ...formData,
      // Include formData for {{selectedProduct}}, {{selectedFacility}} etc.
    };

    // Check visibility condition - support both 'visible' and 'hidden' properties
    final visibleProp = json['visible'];
    final hiddenProp = json['hidden'];

    bool shouldShow = true;

    if (hiddenProp != null) {
      // If hidden property exists, evaluate it
      final isHidden = ConditionalEvaluator.evaluate(
        hiddenProp,
        evalContext,
        screenKey: screenKey,
        stateData: crudCtx?.stateData,
      );
      shouldShow = isHidden != true;
    } else if (visibleProp != null) {
      // Fall back to visible property
      final isVisible = ConditionalEvaluator.evaluate(
        visibleProp,
        evalContext,
        screenKey: screenKey,
        stateData: crudCtx?.stateData,
      );
      shouldShow = isVisible == true;
    }

    // Original behavior: hide if visibility check fails OR if items exist
    if (!shouldShow || items.isNotEmpty) {
      return const SizedBox.shrink();
    }

    // Determine info type from config (use 'infoType' property, default to info)
    final typeString = json['infoType']?.toString().toLowerCase() ?? 'info';
    final infoType = typeString == 'error'
        ? InfoType.error
        : typeString == 'warning'
            ? InfoType.warning
            : typeString == 'success'
                ? InfoType.success
                : InfoType.info;

    final localization = LocalizationContext.maybeOf(context);

    return InfoCard(
      type: infoType,
      title:
          localization?.translate(json['label'] ?? '') ?? (json['label'] ?? ''),
      description: localization?.translate(json['description'] ?? '') ??
          (json['description'] ?? ''),
    );
  }
}

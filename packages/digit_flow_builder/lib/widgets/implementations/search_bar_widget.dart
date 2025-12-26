import 'package:digit_ui_components/widgets/atoms/digit_search_bar.dart';
import 'package:digit_ui_components/widgets/atoms/switch.dart';
import 'package:flutter/material.dart';

import '../../action_handler/action_config.dart';
import '../../blocs/flow_crud_bloc.dart';
import '../flow_widget_interface.dart';
import '../localization_context.dart';

class SearchBarWidget implements FlowWidget {
  @override
  String get format => 'searchBar';

  @override
  Widget build(
    Map<String, dynamic> json,
    BuildContext context,
    void Function(ActionConfig) onAction,
  ) {
    final localization = LocalizationContext.maybeOf(context);
    final hintText = json['label'] ?? '';
    final localizedHint = localization?.translate(hintText) ?? hintText;

    // Check if ID search is enabled in config
    final enableIdSearch = json['enableIdSearch'] ?? false;
    final idSearchLabel = json['idSearchLabel'] ?? 'SEARCH_BY_ID';
    final localizedIdSearchLabel =
        localization?.translate(idSearchLabel) ?? idSearchLabel;

    if (!enableIdSearch) {
      // Original behavior without toggle
      return DigitSearchBar(
        hintText: localizedHint,
        onChanged: (value) {
          _handleSearchChange(value, json, onAction, false);
        },
      );
    }

    // With toggle switch for ID search
    return _SearchBarWithToggle(
      hintText: localizedHint,
      idSearchLabel: localizedIdSearchLabel,
      json: json,
      onAction: onAction,
    );
  }

  void _handleSearchChange(
    String value,
    Map<String, dynamic> json,
    void Function(ActionConfig) onAction,
    bool searchById,
  ) {
    if (value.isNotEmpty) {
      // Determine which action config to use based on toggle state
      final actionKey = searchById ? 'onActionById' : 'onAction';
      final actions = json[actionKey] ?? json['onAction'];

      if (actions != null) {
        final actionsList = List<Map<String, dynamic>>.from(actions);

        for (var raw in actionsList) {
          // Create deep copy to avoid mutating original config
          final actionCopy = Map<String, dynamic>.from(raw);
          actionCopy['properties'] = Map<String, dynamic>.from(
            actionCopy['properties'] ?? {},
          );

          final data = actionCopy['properties']['data'];
          if (data is List && data.isNotEmpty) {
            // Create a copy of the data list and first item
            final dataCopy = List<dynamic>.from(data);
            if (dataCopy[0] is Map<String, dynamic>) {
              dataCopy[0] = Map<String, dynamic>.from(dataCopy[0]);
              dataCopy[0]['value'] = value;
            }
            actionCopy['properties']['data'] = dataCopy;
          }

          final action = ActionConfig.fromJson(actionCopy);
          onAction(action);
        }
      }
    } else {
      FlowCrudStateRegistry().clearAll();
    }
  }
}

class _SearchBarWithToggle extends StatefulWidget {
  final String hintText;
  final String idSearchLabel;
  final Map<String, dynamic> json;
  final void Function(ActionConfig) onAction;

  const _SearchBarWithToggle({
    required this.hintText,
    required this.idSearchLabel,
    required this.json,
    required this.onAction,
  });

  @override
  State<_SearchBarWithToggle> createState() => _SearchBarWithToggleState();
}

class _SearchBarWithToggleState extends State<_SearchBarWithToggle> {
  bool _searchById = false;
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSearchChange(String value) {
    debugPrint('🔍 [SearchBar] _handleSearchChange called');
    debugPrint('🔍 [SearchBar] Search value: "$value"');
    debugPrint('🔍 [SearchBar] Search by ID toggle: $_searchById');

    if (value.isNotEmpty) {
      // Determine which action config to use based on toggle state
      final actionKey = _searchById ? 'onActionById' : 'onAction';
      debugPrint('🔍 [SearchBar] Using action key: $actionKey');

      final actions = widget.json[actionKey] ?? widget.json['onAction'];
      debugPrint('🔍 [SearchBar] Actions found: ${actions != null}');

      if (actions != null) {
        final actionsList = List<Map<String, dynamic>>.from(actions);
        debugPrint('🔍 [SearchBar] Number of actions: ${actionsList.length}');

        for (var raw in actionsList) {
          // Create deep copy to avoid mutating original config
          final actionCopy = Map<String, dynamic>.from(raw);
          actionCopy['properties'] = Map<String, dynamic>.from(
            actionCopy['properties'] ?? {},
          );

          final data = actionCopy['properties']['data'];
          if (data is List && data.isNotEmpty) {
            // Create a copy of the data list and first item
            final dataCopy = List<dynamic>.from(data);
            if (dataCopy[0] is Map<String, dynamic>) {
              dataCopy[0] = Map<String, dynamic>.from(dataCopy[0]);
              dataCopy[0]['value'] = value;
            }
            actionCopy['properties']['data'] = dataCopy;
          }

          debugPrint('🔍 [SearchBar] Action properties: ${actionCopy['properties']}');
          debugPrint('🔍 [SearchBar] Search table (name): ${actionCopy['properties']['name']}');
          debugPrint('🔍 [SearchBar] Search data: ${actionCopy['properties']['data']}');

          final action = ActionConfig.fromJson(actionCopy);
          debugPrint('🔍 [SearchBar] Dispatching SEARCH_EVENT...');
          widget.onAction(action);
        }
      }
    } else {
      debugPrint('🔍 [SearchBar] Empty search, clearing state');
      FlowCrudStateRegistry().clearAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DigitSearchBar(
          controller: _controller,
          hintText: widget.hintText,
          onChanged: _handleSearchChange,
        ),
        const SizedBox(height: 8),
        DigitSwitch(
          label: widget.idSearchLabel,
          value: _searchById,
          mainAxisAlignment: MainAxisAlignment.start,
          onChanged: (value) {
            setState(() {
              _searchById = value;
            });
            // Re-trigger search with current value if there's text
            if (_controller.text.isNotEmpty) {
              _handleSearchChange(_controller.text);
            }
          },
        ),
      ],
    );
  }
}

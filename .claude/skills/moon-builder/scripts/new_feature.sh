#!/bin/bash
# new_feature.sh — Full feature scaffold matching project structure
# Usage: ./scripts/new_feature.sh <feature_name> [lib_path]
# Example: ./scripts/new_feature.sh product
#          ./scripts/new_feature.sh product lib

set -e

FEATURE_NAME="${1}"
LIB_PATH="${2:-lib}"

if [ -z "$FEATURE_NAME" ]; then
  echo "❌  Usage: $0 <feature_name> [lib_path]"
  echo "    Example: $0 product"
  exit 1
fi

SNAKE="${FEATURE_NAME}"
PASCAL=$(echo "$SNAKE" | sed -E 's/(^|_)([a-zA-Z])/\U\2/g')

PAGES_DIR="${LIB_PATH}/pages/${SNAKE}"
ENTITY_FILE="${LIB_PATH}/models/entities/${SNAKE}_entity.dart"
MODEL_FILE="${LIB_PATH}/models/data_class/${SNAKE}_model.dart"
REPO_FILE="${LIB_PATH}/repositories/${SNAKE}_repositories.dart"
SERVICE_FILE="${LIB_PATH}/services/${SNAKE}_service.dart"

if [ -d "$PAGES_DIR" ]; then
  echo "❌  Feature '${SNAKE}' already exists at ${PAGES_DIR}"
  exit 1
fi

echo "🚀  Scaffolding feature: ${PASCAL}"
echo ""

mkdir -p "${LIB_PATH}/models/entities"
mkdir -p "${LIB_PATH}/models/data_class"
mkdir -p "${LIB_PATH}/repositories"
mkdir -p "${LIB_PATH}/services"
mkdir -p "${PAGES_DIR}/widgets"

# ── Entity ────────────────────────────────────────────────────────────────────
cat > "${ENTITY_FILE}" << DART
class ${PASCAL}Entity {
  final String id;

  const ${PASCAL}Entity({
    required this.id,
  });
}
DART

# ── Model ─────────────────────────────────────────────────────────────────────
cat > "${MODEL_FILE}" << DART
import 'package:json_annotation/json_annotation.dart';
import '../entities/${SNAKE}_entity.dart';

part '${SNAKE}_model.g.dart';

@JsonSerializable()
class ${PASCAL}Model {
  final String id;

  const ${PASCAL}Model({
    required this.id,
  });

  factory ${PASCAL}Model.fromJson(Map<String, dynamic> json) =>
      _\$${PASCAL}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${PASCAL}ModelToJson(this);

  ${PASCAL}Entity toEntity() => ${PASCAL}Entity(
        id: id,
      );
}
DART

# ── Repository ────────────────────────────────────────────────────────────────
cat > "${REPO_FILE}" << DART
import '../models/data_class/${SNAKE}_model.dart';

class ${PASCAL}Repositories {
  Future<List<${PASCAL}Model>> getAll() async {
    // TODO: replace with ApiUtil.get('/...') call
    throw UnimplementedError();
  }
}
DART

# ── Service ───────────────────────────────────────────────────────────────────
cat > "${SERVICE_FILE}" << DART
import '../models/entities/${SNAKE}_entity.dart';
import '../repositories/${SNAKE}_repositories.dart';

class ${PASCAL}Service {
  final ${PASCAL}Repositories _repositories;

  ${PASCAL}Service(this._repositories);

  Future<List<${PASCAL}Entity>> getAll() async {
    final models = await _repositories.getAll();
    return models.map((m) => m.toEntity()).toList();
  }
}
DART

# ── State ─────────────────────────────────────────────────────────────────────
cat > "${PAGES_DIR}/${SNAKE}_state.dart" << DART
import '../../models/entities/${SNAKE}_entity.dart';

sealed class ${PASCAL}State {}

class ${PASCAL}Initial extends ${PASCAL}State {}

class ${PASCAL}Loading extends ${PASCAL}State {}

class ${PASCAL}Loaded extends ${PASCAL}State {
  final List<${PASCAL}Entity> items;
  const ${PASCAL}Loaded(this.items);
}

class ${PASCAL}Error extends ${PASCAL}State {
  final String message;
  const ${PASCAL}Error(this.message);
}
DART

# ── Cubit ─────────────────────────────────────────────────────────────────────
cat > "${PAGES_DIR}/${SNAKE}_cubit.dart" << DART
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/${SNAKE}_service.dart';
import '${SNAKE}_state.dart';

class ${PASCAL}Cubit extends Cubit<${PASCAL}State> {
  final ${PASCAL}Service _service;

  ${PASCAL}Cubit(this._service) : super(${PASCAL}Initial());

  Future<void> load() async {
    emit(${PASCAL}Loading());
    try {
      final items = await _service.getAll();
      emit(${PASCAL}Loaded(items));
    } catch (e) {
      emit(${PASCAL}Error(e.toString()));
    }
  }
}
DART

# ── Page ──────────────────────────────────────────────────────────────────────
cat > "${PAGES_DIR}/${SNAKE}_page.dart" << DART
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/${SNAKE}_service.dart';
import '${SNAKE}_cubit.dart';
import '${SNAKE}_state.dart';

class ${PASCAL}Page extends StatelessWidget {
  const ${PASCAL}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ${PASCAL}Cubit(
        context.read<${PASCAL}Service>(),
      )..load(),
      child: const _${PASCAL}View(),
    );
  }
}

class _${PASCAL}View extends StatelessWidget {
  const _${PASCAL}View();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('${PASCAL}')),
      body: BlocBuilder<${PASCAL}Cubit, ${PASCAL}State>(
        builder: (context, state) => switch (state) {
          ${PASCAL}Initial() => const SizedBox.shrink(),
          ${PASCAL}Loading() => const Center(child: CircularProgressIndicator()),
          ${PASCAL}Loaded(:final items) => ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(items[index].id),
              ),
            ),
          ${PASCAL}Error(:final message) => Center(child: Text(message)),
        },
      ),
    );
  }
}
DART

# ── Summary ───────────────────────────────────────────────────────────────────
echo "✅  Feature '${PASCAL}' scaffolded!"
echo ""
echo "📁  Files created:"
echo "    ${ENTITY_FILE}"
echo "    ${MODEL_FILE}  ← run build_runner!"
echo "    ${REPO_FILE}"
echo "    ${SERVICE_FILE}"
echo "    ${PAGES_DIR}/${SNAKE}_state.dart"
echo "    ${PAGES_DIR}/${SNAKE}_cubit.dart"
echo "    ${PAGES_DIR}/${SNAKE}_page.dart"
echo ""
echo "⚠️   Next steps:"
echo "    1. Add fields to entity + model, implement repository"
echo "    2. fvm dart run build_runner build --delete-conflicting-outputs"
echo "    3. Add to lib/routing/routers.dart (enum) and lib/routing/router_config.dart:"
echo "       GoRoute("
echo "         path: '/${SNAKE}',"
echo "         name: '${SNAKE}',"
echo "         builder: (context, state) => const ${PASCAL}Page(),"
echo "       ),"

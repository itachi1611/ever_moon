#!/bin/bash
# new_page.sh — Scaffold presentation layer only (page + cubit + state)
# Usage: ./scripts/new_page.sh <page_name> [lib_path]
# Example: ./scripts/new_page.sh splash
#          ./scripts/new_page.sh forgot_password lib

set -e

PAGE_NAME="${1}"
LIB_PATH="${2:-lib}"

if [ -z "$PAGE_NAME" ]; then
  echo "❌  Usage: $0 <page_name> [lib_path]"
  echo "    Example: $0 splash"
  echo "    Example: $0 forgot_password lib"
  exit 1
fi

SNAKE="${PAGE_NAME}"
PASCAL=$(echo "$SNAKE" | sed -E 's/(^|_)([a-zA-Z])/\U\2/g')
PAGE_DIR="${LIB_PATH}/pages/${SNAKE}"

if [ -d "$PAGE_DIR" ]; then
  echo "❌  Page '${SNAKE}' already exists at ${PAGE_DIR}"
  exit 1
fi

echo "🚀  Scaffolding page: ${PASCAL}"
echo ""

mkdir -p "${PAGE_DIR}"

# ── State ─────────────────────────────────────────────────────────────────────
cat > "${PAGE_DIR}/${SNAKE}_state.dart" << DART
sealed class ${PASCAL}State {}

class ${PASCAL}Initial extends ${PASCAL}State {}

class ${PASCAL}Loading extends ${PASCAL}State {}

class ${PASCAL}Loaded extends ${PASCAL}State {}

class ${PASCAL}Error extends ${PASCAL}State {
  final String message;
  const ${PASCAL}Error(this.message);
}
DART

# ── Cubit ─────────────────────────────────────────────────────────────────────
cat > "${PAGE_DIR}/${SNAKE}_cubit.dart" << DART
import 'package:flutter_bloc/flutter_bloc.dart';
import '${SNAKE}_state.dart';

class ${PASCAL}Cubit extends Cubit<${PASCAL}State> {
  ${PASCAL}Cubit() : super(${PASCAL}Initial());

  Future<void> load() async {
    emit(${PASCAL}Loading());
    try {
      // TODO: call service
      emit(${PASCAL}Loaded());
    } catch (e) {
      emit(${PASCAL}Error(e.toString()));
    }
  }
}
DART

# ── Page ──────────────────────────────────────────────────────────────────────
cat > "${PAGE_DIR}/${SNAKE}_page.dart" << DART
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '${SNAKE}_cubit.dart';
import '${SNAKE}_state.dart';

class ${PASCAL}Page extends StatelessWidget {
  const ${PASCAL}Page({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ${PASCAL}Cubit()..load(),
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
          ${PASCAL}Loaded() => const Center(child: Text('${PASCAL}')),
          ${PASCAL}Error(:final message) => Center(child: Text(message)),
        },
      ),
    );
  }
}
DART

echo "✅  Page '${PASCAL}' created!"
echo ""
echo "📁  Files created:"
echo "    ${PAGE_DIR}/${SNAKE}_state.dart"
echo "    ${PAGE_DIR}/${SNAKE}_cubit.dart"
echo "    ${PAGE_DIR}/${SNAKE}_page.dart"
echo ""
echo "⚠️   Next steps:"
echo "    1. Add GoRoute to lib/routing/routers.dart (enum) and lib/routing/router_config.dart:"
echo "       GoRoute("
echo "         path: '/${SNAKE}',"
echo "         name: '${SNAKE}',"
echo "         builder: (context, state) => const ${PASCAL}Page(),"
echo "       ),"
echo "    2. Wire up your service in ${SNAKE}_cubit.dart if needed"

#!/bin/bash
# add_model.sh — Add a json_serializable model + domain entity to an existing feature
# Usage: ./add_model.sh <model_name> [feature_path]
# Example: ./add_model.sh product_review
#          ./add_model.sh product_review lib/features/product

set -e

MODEL_NAME="${1}"
FEATURE_PATH="${2:-lib/features/${MODEL_NAME}}"

if [[ -z "$MODEL_NAME" ]]; then
  echo "❌ Usage: $0 <model_name> [feature_path]"
  echo "   Example: $0 product_review"
  echo "   Example: $0 product_review lib/features/product"
  exit 1
fi

to_pascal() {
  echo "$1" | sed -E 's/(^|_)([a-z])/\U\2/g'
}

SNAKE="${MODEL_NAME}"
PASCAL=$(to_pascal "$MODEL_NAME")
ENTITY_DIR="${FEATURE_PATH}/domain/entities"
MODEL_DIR="${FEATURE_PATH}/data/models"

mkdir -p "${ENTITY_DIR}"
mkdir -p "${MODEL_DIR}"

ENTITY_FILE="${ENTITY_DIR}/${SNAKE}_entity.dart"
MODEL_FILE="${MODEL_DIR}/${SNAKE}_model.dart"

if [[ -f "$ENTITY_FILE" ]]; then
  echo "❌ Entity '${SNAKE}_entity.dart' already exists"
  exit 1
fi

if [[ -f "$MODEL_FILE" ]]; then
  echo "❌ Model '${SNAKE}_model.dart' already exists"
  exit 1
fi

# Entity
cat > "${ENTITY_FILE}" <<DART
class ${PASCAL}Entity {
  final String id;

  const ${PASCAL}Entity({
    required this.id,
  });
}
DART

# Model
cat > "${MODEL_FILE}" <<DART
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/${SNAKE}_entity.dart';

part '${SNAKE}_model.g.dart';

@JsonSerializable()
class ${PASCAL}Model {
  final String id;

  const ${PASCAL}Model({required this.id});

  factory ${PASCAL}Model.fromJson(Map<String, dynamic> json) =>
      _\$${PASCAL}ModelFromJson(json);

  Map<String, dynamic> toJson() => _\$${PASCAL}ModelToJson(this);

  ${PASCAL}Entity toEntity() => ${PASCAL}Entity(id: id);
}
DART

echo "✅ Created ${PASCAL} model + entity"
echo ""
echo "📁 Files:"
echo "   ${ENTITY_FILE}"
echo "   ${MODEL_FILE}"
echo ""

# Run build_runner if we're inside a Flutter project (pubspec.yaml exists)
if [[ -f "pubspec.yaml" ]]; then
  echo "⚙️  Running build_runner..."
  fvm dart run build_runner build --delete-conflicting-outputs
  echo ""
  echo "✅ build_runner complete — ${SNAKE}_model.g.dart generated"
else
  echo "📝 Next steps:"
  echo "   1. Add your fields to both ${SNAKE}_entity.dart and ${SNAKE}_model.dart"
  echo "   2. Run from your project root:"
  echo "      fvm dart run build_runner build --delete-conflicting-outputs"
fi

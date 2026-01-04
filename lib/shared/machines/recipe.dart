import '../resources/resource_type.dart';
import 'machine_type.dart';

/// Represents a single input requirement for a recipe
class RecipeInput {
  final ResourceType resource;
  final int amount;

  const RecipeInput({
    required this.resource,
    required this.amount,
  });

  @override
  String toString() {
    return '$amount ${resource.displayName}';
  }
}

/// Represents a crafting/processing recipe
class Recipe {
  final String id;
  final List<RecipeInput> inputs;  // ✓ Changed to support multiple inputs
  final ResourceType output;
  final int outputAmount;
  final double processingTime;  // Seconds

  const Recipe({
    required this.id,
    required this.inputs,
    required this.output,
    required this.outputAmount,
    required this.processingTime,
  });

  /// Check if inputs list contains a specific resource
  bool requiresResource(ResourceType resource) {
    return inputs.any((input) => input.resource == resource);
  }

  /// Get amount required for a specific resource
  int getRequiredAmount(ResourceType resource) {
    final input = inputs.firstWhere(
      (input) => input.resource == resource,
      orElse: () => RecipeInput(resource: resource, amount: 0),
    );
    return input.amount;
  }

  /// Get total number of input items required
  int get totalInputItems {
    return inputs.fold(0, (sum, input) => sum + input.amount);
  }

  @override
  String toString() {
    final inputStr = inputs.map((i) => i.toString()).join(' + ');
    return '$inputStr → $outputAmount ${output.displayName} (${processingTime}s)';
  }

  /// Format for UI display
  String get displayName {
    return '${output.displayName} (${processingTime}s)';
  }

  /// Get input summary for UI
  String get inputSummary {
    return inputs.map((i) => i.toString()).join(', ');
  }
}

/// Available recipes
const Map<String, Recipe> recipes = {
  'ironBar': Recipe(
    id: 'ironBar',
    inputs: [
      RecipeInput(resource: ResourceType.iron, amount: 3),  // ✓ 3 iron ore
      RecipeInput(resource: ResourceType.coal, amount: 10),     // ✓ 10 coal
    ],
    output: ResourceType.ironBar,
    outputAmount: 1,
    processingTime: 20,
  ),
  
  'energyCube': Recipe(
    id: 'energyCube',
    inputs: [
      RecipeInput(resource: ResourceType.energyCatalyst, amount: 5),  // ✓ 5 energy catalyst
      RecipeInput(resource: ResourceType.coal, amount: 20),            // ✓ 20 coal
    ],
    output: ResourceType.energyCube,
    outputAmount: 1,
    processingTime: 45,
  ),
};

/// Get recipes that a machine can process
List<Recipe> getRecipesForMachine(MachineType machineType) {
  if (machineType == MachineType.smelter) {
    return recipes.values.toList();
  }
  return [];
}

/// Get recipe by output resource type
Recipe? getRecipeByOutput(ResourceType output) {
  for (final recipe in recipes.values) {
    if (recipe.output == output) {
      return recipe;
    }
  }
  return null;
}

/// Get all recipes that use a specific input resource
List<Recipe> getRecipesByInput(ResourceType input) {
  return recipes.values
      .where((recipe) => recipe.requiresResource(input))
      .toList();
}
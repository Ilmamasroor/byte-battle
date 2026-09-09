from collections import Counter
from app.models.recommendation_models import RecommendationRequest, RecommendationResponse

CHALLENGE_MAPPING = {
    "multithreading": {
        "shared_resource_identification": "Shared Resource Identification Challenge",
        "synchronization_misuse": "Synchronization Practice Challenge",
        "race_condition_reasoning": "Race Condition Deep-Dive Battle",
        "deadlock_reasoning": "Deadlock Scenario Challenge",
        "execution_order_assumption": "Execution Order Tracing Exercise",
        "boundary_condition_error": "Boundary Condition Challenge",
        "other": "General Multithreading Review",
    },
    "core_java": {
        "variable_scope_misunderstanding": "Variable Scope Practice Challenge",
        "data_type_conversion_error": "Type Conversion Challenge",
        "control_flow_logic_error": "Control Flow Debugging Exercise",
        "method_signature_misuse": "Method Signature Practice Challenge",
        "array_index_error": "Array Indexing Challenge",
        "other": "General Core Java Review",
    },
    "oop": {
        "encapsulation_violation": "Encapsulation Practice Challenge",
        "inheritance_misuse": "Inheritance Design Challenge",
        "polymorphism_misunderstanding": "Polymorphism Practice Challenge",
        "interface_abstract_class_confusion": "Interface vs Abstract Class Exercise",
        "constructor_misuse": "Constructor Chaining Challenge",
        "other": "General OOP Review",
    },
    "collections": {
        "wrong_collection_choice": "Collection Selection Challenge",
        "concurrent_modification_error": "Safe Iteration Challenge",
        "iterator_misuse": "Iterator Practice Exercise",
        "generics_type_error": "Generics Type-Safety Challenge",
        "null_handling_error": "Null Handling Challenge",
        "other": "General Collections Review",
    },
    "exception_handling": {
        "improper_exception_catching": "Exception Catching Practice Challenge",
        "resource_not_closed": "Try-With-Resources Challenge",
        "custom_exception_misuse": "Custom Exception Design Challenge",
        "checked_unchecked_confusion": "Checked vs Unchecked Exercise",
        "exception_swallowing": "Exception Handling Best Practices Challenge",
        "other": "General Exception Handling Review",
    },
    "arrays": {
        "index_out_of_bounds_error": "Array Bounds Practice Challenge",
        "off_by_one_error": "Off-by-One Debugging Exercise",
        "array_traversal_logic_error": "Array Traversal Challenge",
        "resizing_capacity_misunderstanding": "Dynamic Array Challenge",
        "multidimensional_array_confusion": "Multidimensional Array Exercise",
        "other": "General Arrays Review",
    },
    "linked_lists": {
        "pointer_reference_error": "Pointer Reference Practice Challenge",
        "traversal_termination_error": "Safe Traversal Challenge",
        "insertion_deletion_logic_error": "Node Insertion/Deletion Challenge",
        "head_tail_tracking_error": "Head/Tail Tracking Exercise",
        "cycle_detection_misunderstanding": "Cycle Detection Challenge",
        "other": "General Linked Lists Review",
    },
    "searching": {
        "search_boundary_error": "Binary Search Bounds Challenge",
        "incorrect_search_condition": "Search Condition Practice Challenge",
        "unsorted_data_assumption": "Sorted Data Assumption Exercise",
        "time_complexity_misunderstanding": "Search Complexity Challenge",
        "other": "General Searching Review",
    },
    "sorting": {
        "comparator_logic_error": "Comparator Logic Challenge",
        "stability_misunderstanding": "Sort Stability Exercise",
        "in_place_vs_extra_space_confusion": "Space Complexity Challenge",
        "edge_case_handling": "Sorting Edge Cases Challenge",
        "algorithm_choice_misunderstanding": "Algorithm Selection Challenge",
        "other": "General Sorting Review",
    },
    "trees": {
        "traversal_order_error": "Tree Traversal Challenge",
        "recursion_base_case_error": "Recursion Base Case Exercise",
        "balance_property_misunderstanding": "Tree Balance Challenge",
        "node_reference_error": "Node Reference Practice Challenge",
        "depth_height_confusion": "Tree Depth/Height Exercise",
        "other": "General Trees Review",
    },
}

DIMENSION_FALLBACK = {
    "conceptUnderstanding": "Concept Review Challenge",
    "decisionMaking": "Quick Decision Battle",
    "boundaryConditions": "Boundary Condition Challenge",
    "codingImplementation": "Implementation Practice Challenge",
    "hintDependency": "Independent Problem-Solving Challenge",
}

def get_recommendation(request: RecommendationRequest) -> RecommendationResponse:
    topic_key = request.topic.lower().replace(" ", "_")
    topic_mapping = CHALLENGE_MAPPING.get(topic_key, {})

    # --- Tier 1: most repeated mistake ---
    if request.repeatedMistakes:
        counts = Counter(request.repeatedMistakes)
        most_common_category, count = counts.most_common(1)[0]

        if most_common_category != "other" and most_common_category in topic_mapping:
            challenge = topic_mapping[most_common_category]
            reason = (
                f"You've repeated the '{most_common_category}' mistake {count} time(s) in "
                f"{request.topic}. This usually means the underlying issue is being missed, "
                f"not just the fix — practice {challenge.lower()} before moving to related concepts."
            )
            return RecommendationResponse(
                userId=request.userId,
                topic=request.topic,
                targetErrorCategory=most_common_category,
                recommendedChallengeType=challenge,
                reason=reason,
                basis="repeated_error"
            )

    # --- Tier 2: weakest diagnosis dimension ---
    dimensions = {
        "conceptUnderstanding": request.conceptUnderstanding,
        "decisionMaking": request.decisionMaking,
        "boundaryConditions": request.boundaryConditions,
        "codingImplementation": request.codingImplementation,
        "hintDependency": request.hintDependency,
    }
    assessed = {k: v for k, v in dimensions.items() if v is not None}

    if assessed:
        weakest_dimension = min(assessed, key=assessed.get)
        weakest_score = assessed[weakest_dimension]
        challenge = DIMENSION_FALLBACK[weakest_dimension]
        reason = (
            f"Your {weakest_dimension} score ({weakest_score}%) is lower than your other "
            f"areas in {request.topic}, so we recommend the {challenge}."
        )
        return RecommendationResponse(
            userId=request.userId,
            topic=request.topic,
            targetErrorCategory=None,
            recommendedChallengeType=challenge,
            reason=reason,
            basis="weakest_dimension"
        )

    # --- Tier 3: no data at all yet ---
    return RecommendationResponse(
        userId=request.userId,
        topic=request.topic,
        targetErrorCategory=None,
        recommendedChallengeType=f"General {request.topic} Practice",
        reason="No performance data available yet — starting with general practice.",
        basis="insufficient_data"
    )
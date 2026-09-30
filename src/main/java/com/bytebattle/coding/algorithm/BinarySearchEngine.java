package com.bytebattle.coding.algorithm;


import org.springframework.stereotype.Component;

@Component
public class BinarySearchEngine {

    /**
     * Returns the FIRST occurrence of target if duplicates exist.
     * This semantic is explicit per doc §23 — don't leave it ambiguous.
     */
    public BinarySearchResult search(BinarySearchRequest request) {
        int[] array = request.sortedArray();
        int target = request.target();

        int low = 0;
        int high = array.length - 1;
        int comparisons = 0;
        int foundIndex = -1;

        while (low <= high) {
            int mid = low + (high - low) / 2;
            comparisons++;

            if (array[mid] == target) {
                foundIndex = mid;
                high = mid - 1; // keep searching left for the FIRST occurrence
            } else if (array[mid] < target) {
                low = mid + 1;
            } else {
                high = mid - 1;
            }
        }

        return new BinarySearchResult(foundIndex, comparisons, foundIndex != -1);
    }
}
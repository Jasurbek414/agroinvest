package uz.agroinvest.common.enums;

/**
 * Structured animal type within LIVESTOCK/POULTRY projects (VARCHAR + CHECK in
 * DB - see V10 - so adding values only needs the CHECK constraint updated).
 */
public enum AnimalType {
    CHICKEN,
    SHEEP,
    CATTLE,
    GOAT,
    HORSE,
    FISH,
    OTHER
}

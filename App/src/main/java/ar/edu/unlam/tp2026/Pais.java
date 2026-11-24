package ar.edu.unlam.tp2026;

public record Pais(int idPais, String nombre) {
    @Override public String toString() { return nombre; }
}

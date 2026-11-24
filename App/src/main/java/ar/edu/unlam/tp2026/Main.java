package ar.edu.unlam.tp2026;

import javax.swing.*;

public final class Main {
    private Main() {}
    public static void main(String[] args) {
        SwingUtilities.invokeLater(() -> {
            try {
                UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
                new ClubFrame(new ClubDAO()).setVisible(true);
            } catch (Exception ex) {
                JOptionPane.showMessageDialog(null, ex.getMessage(), "Error de inicio", JOptionPane.ERROR_MESSAGE);
            }
        });
    }
}

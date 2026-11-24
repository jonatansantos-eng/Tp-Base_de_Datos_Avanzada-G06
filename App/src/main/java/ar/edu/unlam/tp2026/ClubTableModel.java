package ar.edu.unlam.tp2026;

import javax.swing.table.AbstractTableModel;
import java.util.ArrayList;
import java.util.List;

public final class ClubTableModel extends AbstractTableModel {
    private final String[] columns = {"ID", "ID País", "Club"};
    private List<Club> rows = new ArrayList<>();
    public void setRows(List<Club> rows) { this.rows = new ArrayList<>(rows); fireTableDataChanged(); }
    public Club get(int row) { return rows.get(row); }
    @Override public int getRowCount() { return rows.size(); }
    @Override public int getColumnCount() { return columns.length; }
    @Override public String getColumnName(int col) { return columns[col]; }
    @Override public Object getValueAt(int row, int col) {
        Club c=rows.get(row); return switch(col){case 0 -> c.idClub(); case 1 -> c.idPais(); default -> c.nombreClub();};
    }
}

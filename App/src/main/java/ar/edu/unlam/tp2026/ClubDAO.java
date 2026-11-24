package ar.edu.unlam.tp2026;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

public final class ClubDAO {
    public List<Club> consultar(Integer idClub) throws SQLException {
        List<Club> items = new ArrayList<>();
        try (Connection cn = DatabaseConfig.open();
             CallableStatement cs = cn.prepareCall("{call mundial.sp_club_Consultar(?)}")) {
            if (idClub == null) cs.setNull(1, Types.INTEGER); else cs.setInt(1, idClub);
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) {
                    items.add(new Club(rs.getInt("id_club"), rs.getInt("id_pais"), rs.getString("nombre_club")));
                }
            }
        }
        return items;
    }

    public List<Pais> consultarPaises() throws SQLException {
        List<Pais> items = new ArrayList<>();
        try (Connection cn = DatabaseConfig.open();
             CallableStatement cs = cn.prepareCall("{call mundial.sp_pais_Consultar(?)}")) {
            cs.setNull(1, Types.INTEGER);
            try (ResultSet rs = cs.executeQuery()) {
                while (rs.next()) items.add(new Pais(rs.getInt("id_pais"), rs.getString("nombre")));
            }
        }
        return items;
    }

    public int alta(int idPais, String nombre) throws SQLException {
        try (Connection cn = DatabaseConfig.open();
             CallableStatement cs = cn.prepareCall("{call mundial.sp_club_Alta(?,?)}")) {
            cs.setInt(1, idPais); cs.setString(2, nombre.trim());
            boolean hasResult = cs.execute();
            if (hasResult) try (ResultSet rs = cs.getResultSet()) {
                if (rs.next()) return rs.getInt(1);
            }
            return 0;
        }
    }

    public void modificar(int idClub, int idPais, String nombre) throws SQLException {
        try (Connection cn = DatabaseConfig.open();
             CallableStatement cs = cn.prepareCall("{call mundial.sp_club_Modificar(?,?,?)}")) {
            cs.setInt(1, idClub); cs.setInt(2, idPais); cs.setString(3, nombre.trim()); cs.execute();
        }
    }

    public void baja(int idClub) throws SQLException {
        try (Connection cn = DatabaseConfig.open();
             CallableStatement cs = cn.prepareCall("{call mundial.sp_club_Baja(?)}")) {
            cs.setInt(1, idClub); cs.execute();
        }
    }
}

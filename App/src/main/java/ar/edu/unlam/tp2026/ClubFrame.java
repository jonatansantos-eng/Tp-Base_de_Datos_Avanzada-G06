package ar.edu.unlam.tp2026;

import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.sql.SQLException;

public final class ClubFrame extends JFrame {
    private final ClubDAO dao;
    private final JTextField idField = new JTextField(8);
    private final JTextField nombreField = new JTextField(28);
    private final JComboBox<Pais> paisCombo = new JComboBox<>();
    private final ClubTableModel model = new ClubTableModel();
    private final JTable table = new JTable(model);
    private final JLabel status = new JLabel("Listo");

    public ClubFrame(ClubDAO dao) throws SQLException {
        super("TP2026 - Gestión de clubes"); this.dao=dao;
        setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
        setMinimumSize(new Dimension(760, 500)); setLocationRelativeTo(null);
        idField.setEditable(false);
        build(); loadCountries(); refresh();
    }

    private void build() {
        JPanel root=new JPanel(new BorderLayout(10,10)); root.setBorder(new EmptyBorder(14,14,14,14));
        JPanel form=new JPanel(new GridBagLayout()); GridBagConstraints g=new GridBagConstraints();
        g.insets=new Insets(4,4,4,4); g.anchor=GridBagConstraints.WEST;
        add(form,g,0,"ID:",idField); add(form,g,1,"País:",paisCombo); add(form,g,2,"Nombre del club:",nombreField);
        JPanel buttons=new JPanel(new FlowLayout(FlowLayout.LEFT));
        JButton nuevo=new JButton("Nuevo"), guardar=new JButton("Guardar"), modificar=new JButton("Modificar"), eliminar=new JButton("Eliminar"), actualizar=new JButton("Actualizar");
        buttons.add(nuevo);buttons.add(guardar);buttons.add(modificar);buttons.add(eliminar);buttons.add(actualizar);
        JPanel north=new JPanel(new BorderLayout()); north.add(form,BorderLayout.CENTER);north.add(buttons,BorderLayout.SOUTH);
        root.add(north,BorderLayout.NORTH); root.add(new JScrollPane(table),BorderLayout.CENTER); root.add(status,BorderLayout.SOUTH); setContentPane(root);
        table.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        table.getSelectionModel().addListSelectionListener(e -> { if(!e.getValueIsAdjusting()) selectRow(); });
        nuevo.addActionListener(e -> clear()); guardar.addActionListener(e -> run(() -> { validateForm(); dao.alta(selectedCountry().idPais(),nombreField.getText()); clear(); refresh(); status.setText("Club creado."); }));
        modificar.addActionListener(e -> run(() -> { int id=requireId(); validateForm(); dao.modificar(id,selectedCountry().idPais(),nombreField.getText()); refresh(); status.setText("Club modificado."); }));
        eliminar.addActionListener(e -> run(() -> { int id=requireId(); if(JOptionPane.showConfirmDialog(this,"¿Eliminar el club seleccionado?","Confirmar",JOptionPane.YES_NO_OPTION)==JOptionPane.YES_OPTION){dao.baja(id);clear();refresh();status.setText("Club eliminado.");} }));
        actualizar.addActionListener(e -> run(this::refresh));
        pack(); setLocationRelativeTo(null);
    }

    private void add(JPanel p, GridBagConstraints g, int y, String label, JComponent field){g.gridx=0;g.gridy=y;g.weightx=0;p.add(new JLabel(label),g);g.gridx=1;g.weightx=1;g.fill=GridBagConstraints.HORIZONTAL;p.add(field,g);}
    private void loadCountries() throws SQLException { for(Pais p:dao.consultarPaises()) paisCombo.addItem(p); }
    private void refresh() throws SQLException { model.setRows(dao.consultar(null)); }
    private void clear(){idField.setText("");nombreField.setText("");if(paisCombo.getItemCount()>0)paisCombo.setSelectedIndex(0);table.clearSelection();}
    private void selectRow(){int row=table.getSelectedRow();if(row<0)return;Club c=model.get(table.convertRowIndexToModel(row));idField.setText(String.valueOf(c.idClub()));nombreField.setText(c.nombreClub());for(int i=0;i<paisCombo.getItemCount();i++)if(paisCombo.getItemAt(i).idPais()==c.idPais()){paisCombo.setSelectedIndex(i);break;}}
    private Pais selectedCountry(){return (Pais)paisCombo.getSelectedItem();}
    private int requireId(){if(idField.getText().isBlank())throw new IllegalArgumentException("Seleccione un club.");return Integer.parseInt(idField.getText());}
    private void validateForm(){if(selectedCountry()==null)throw new IllegalArgumentException("Seleccione un país.");if(nombreField.getText().isBlank())throw new IllegalArgumentException("Ingrese el nombre del club.");}
    private void run(SqlAction action){try{action.run();}catch(Exception ex){String msg=ex.getMessage();if(ex instanceof SQLException sql && sql.getNextException()!=null)msg=sql.getNextException().getMessage();status.setText("Error");JOptionPane.showMessageDialog(this,msg,"Error",JOptionPane.ERROR_MESSAGE);}}
    @FunctionalInterface private interface SqlAction{void run() throws Exception;}
}

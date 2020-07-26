public class Sensors.MainWindow : Gtk.Window {
    public DBusServer dbusserver;
    public Services.Sensor sensors_data;
    public Views.MainList list_model;

    public MainWindow (SensorsApp app) {
        this.set_application (app);

        define_window();

        dbusserver = DBusServer.get_default ();

        Timeout.add_seconds (2, () => {
          list_model.feed (sensors_data.updated_data());

          // foreach (Models.SensorRecord data in sensors_data.updated_data()) {
          //   debug("%s -> %s -> %s", data.group, data.description, data.value);
          // }
            //  dbusserver.update (22);
            return true;
        });
    }

    private void define_window () {
        var grid = new Gtk.Grid ();
        grid.column_spacing = 6;
        grid.row_spacing = 6;

        var update_button = new Gtk.Button.with_label (_("Update"));

        update_button.clicked.connect (() => {
            dbusserver.is_visible (true);
        });

        // add first row of widgets
        grid.attach (update_button, 0, 0, 1, 1);

        list_model = new Views.MainList();
        sensors_data = new Services.Sensor();

        grid.attach_next_to (list_model.view, update_button, Gtk.PositionType.BOTTOM, 1, 1);

        this.add(grid);
    }
}

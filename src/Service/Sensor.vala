public class Service.Sensor {
    private string last_stdout;
    private string last_stderr;
    private int last_status;

    public signal void on_sensor_update (DataModel.SensorRecord[] sensors_data);

    public Sensor (int update_interval) {
        Timeout.add_seconds (update_interval, () => {
          this.on_sensor_update (this.updated_data());
          return true;
        });
    }

    public DataModel.SensorRecord[] updated_data () {
        DataModel.SensorRecord[] sensor_records = {};

        try {
          Process.spawn_command_line_sync (
              "sensors -u",
              out last_stdout,
              out last_stderr,
              out last_status
          );
        } catch (GLib.SpawnError e) {
          debug ("Failed to get data");
        }

        string[] lines = last_stdout.split ("\n");
        string group_name = "";
        string first_column, second_column;
        string item_hash = "";
        string column_type = "";
        string column_description = "";

        foreach (string str in lines) {
            string[] fields = str.split (":");
            first_column = (bool)fields[0] ? fields[0] : "";

            if (fields.length == 2) {
              second_column = (bool)fields[1] ? fields[1] : "";
            } else {
              second_column = "";
            }

            if (first_column.length > 0 && first_column.has_prefix("  ") == false) {
                group_name = first_column.strip();
            } else {
                first_column = first_column.strip();
            }

            column_type = "";
            column_description = first_column;

            if (column_description.contains("_")) {
                string[] first_column_fields = column_description.split("_");

                column_description = first_column_fields[0];
                column_type = first_column_fields[1];
            }

            if (column_description.length > 0 && second_column.length > 0) {
                item_hash = group_name + first_column;
                item_hash = GLib.Checksum.compute_for_string (ChecksumType.MD5, item_hash, item_hash.length);

                sensor_records += new DataModel.SensorRecord (
                    item_hash,
                    group_name,
                    group_name == column_description ? "" : column_description,
                    column_type,
                    second_column
                );
            }
        };

        return sensor_records;
    }

    public int average_temp (DataModel.SensorRecord[] data, string records_selected) {
        double total = 0;
        int counter = 0;

        foreach (DataModel.SensorRecord str in data) {
            if (
              records_selected.index_of(str.id) >= 0
              && str.type == "input"
              && str.description.contains ("temp")
            ) {
                total += double.parse (str.value);
                counter++;
            }
        };

        return counter > 0 ? (int) (total/counter) : 0;
    }
}

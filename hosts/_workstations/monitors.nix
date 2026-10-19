{...}: {
  modules.system.desktop = {
    monitorCatalog = {
      dell-p2416d = {
        name = "Dell";
        manufacturer = "Dell Inc.";
        model = "DELL P2416D";
        serial = "07C5373I053U";
        resolution = {
          x = 2560;
          y = 1440;
        };
        refresh_rate = 59.951;
      };
      gigabyte-m34wq = {
        name = "Gigabyte";
        manufacturer = "GIGA-BYTE TECHNOLOGY CO., LTD.";
        model = "M34WQ";
        resolution = {
          x = 3440;
          y = 1440;
        };
        refresh_rate = 59.973;
      };
      hp-e27u-g4 = {
        name = "HP";
        manufacturer = "HP Inc.";
        model = "HP E27u G4";
        serial = "CN42231TDD";
        resolution = {
          x = 2560;
          y = 1440;
        };
        refresh_rate = 59.951;
      };
      asus-be27a = {
        name = "ASUS";
        manufacturer = "ASUSTek COMPUTER INC";
        model = "BE27A";
        serial = "H5LMQS040197";
        resolution = {
          x = 2560;
          y = 1440;
        };
        refresh_rate = 59.951;
      };
      framework-panel = {
        name = "laptop";
        manufacturer = "BOE";
        model = "NE135A1M-NY1";
        resolution = {
          x = 2880;
          y = 1920;
        };
        refresh_rate = 120.0;
        scale = 2.0;
      };
    };

    monitorGroups = {
      desk-main = {
        dell-p2416d = {
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.1333;
          transform = 3;
        };
        gigabyte-m34wq = {
          position = {
            x = 1270;
            y = 359;
          };
        };
      };
      desk-gigabyte = {
        gigabyte-m34wq = {
          position = {
            x = 2072;
            y = 293;
          };
          scale = 1.1;
        };
      };
      work-externals = {
        hp-e27u-g4 = {
          position = {
            x = 1440;
            y = 0;
          };
        };
        asus-be27a = {
          position = {
            x = 4000;
            y = 0;
          };
        };
      };
    };
  };
}

class i2cmb_environment extends ncsu_component;

  i2cmb_env_configuration configuration;
  i2c_agent               i2c_ag;
  wb_agent                wb_ag;
  i2cmb_predictor         pred;
  i2cmb_scoreboard        scbd;
  i2cmb_coverage          coverage;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
  endfunction 

  function void set_configuration(i2cmb_env_configuration cfg);
    configuration = cfg;
  endfunction

  virtual function void build();
    i2c_ag = new("i2c_ag", this);
    i2c_ag.set_configuration(configuration.i2c_agent_config);
    i2c_ag.build();
    wb_ag = new("wb_ag", this);
    wb_ag.set_configuration(configuration.wb_agent_config);
    wb_ag.build();
    pred = new("pred", this);
    pred.set_configuration(configuration);
    pred.build();
    scbd = new("scbd", this);
    scbd.build();
    coverage = new("coverage", this);
    coverage.set_configuration(configuration);
    coverage.build();
    wb_ag.connect_subscriber(coverage);
    wb_ag.connect_subscriber(pred);
    pred.set_scoreboard(scbd);
    i2c_ag.connect_subscriber(scbd);
  endfunction

  function wb_agent get_wb_agent();
    return wb_ag;
  endfunction

  function i2c_agent get_i2c_agent();
    return i2c_ag;
  endfunction

  virtual task run();
     wb_ag.run();
     i2c_ag.run();
  endtask
endclass
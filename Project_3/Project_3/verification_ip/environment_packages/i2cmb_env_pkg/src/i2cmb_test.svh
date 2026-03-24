class i2cmb_test extends ncsu_component;

  i2cmb_env_configuration  cfg;
  i2cmb_environment        env;
  i2cmb_generator          gen;
  string test_name;

  function new(string name = "", ncsu_component_base parent = null); 
    super.new(name,parent);
    if(!$value$plusargs("GEN_TEST_TYPE=%s", test_name)) begin
      $display("FATAL: +GEN_TEST_TYPE plusarg not found on command line");
      $fatal;
    end
    $display("GEN_TEST_TYPE = %s", test_name);
    cfg = new("cfg");
    //cfg.sample_coverage();
    env = new("env", this);
    env.set_configuration(cfg);
    env.build();
    gen = new("gen", this);
    gen.set_agent(env.get_wb_agent(), env.get_i2c_agent());
  endfunction

  virtual task run();
    env.run();
    gen.run();
  endtask
endclass
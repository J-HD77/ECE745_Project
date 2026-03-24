class ncsu_component_base extends ncsu_object;

  ncsu_component_base parent;

  function new(string name="", ncsu_component_base  parent=null); 
    super.new(name);
    this.parent = parent;
  endfunction

  virtual function string get_name();
    return(name);
  endfunction

  virtual function string get_full_name();
    if ( parent == null ) return (name);
    else                  return ({parent.get_full_name(),".",name});
  endfunction

endclass

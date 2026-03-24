class i2cmb_scoreboard extends ncsu_component#(.T(i2c_transaction));

   function new(string name = "", ncsu_component_base parent = null);
      super.new(name, parent);
   endfunction

   T trans_in;
   T trans_out;

   virtual function void nb_transport(input T input_trans, output T output_trans);
      this.trans_in = input_trans;
      this.trans_in.int_data = new[this.trans_in.data.size()];
      foreach(this.trans_in.data[i]) this.trans_in.int_data[i] = this.trans_in.data[i];
      //$display({get_full_name()," nb_transport: expected transaction ", trans_in.convert2string()});
      output_trans = trans_out;
   endfunction

   virtual function void nb_put(T trans);
      // if(trans.data[trans.data.size()-3] == 131) begin
      //    trans.data = new[trans.data.size()-2] (trans.data);
      // end
      // if(trans.data[trans.data.size()-1] == 0) begin
      //    trans.data = new[trans.data.size()-1] (trans.data);
      // end
      trans.int_data = new[trans.data.size()];  
      foreach(trans.data[i]) trans.int_data[i] = trans.data[i];    
      // foreach (trans.data[i]) begin
      //     if (i < trans.data.size() - 1) begin  // Skip the last element
      //         trans.int_data[i] = trans.data[i];
      //     end
      // end
      //$display({get_full_name(),"           nb_put:   actual transaction ", trans.convert2string()});
      if(this.trans_in.compare(trans)) begin 
        $display("%-30s nb_put:   actual transaction %-50s %-30s", get_full_name(), trans.convert2string(), "wb_transaction MATCH!");
      end
      else begin 
        $display("%-30s nb_put:   actual transaction %-50s %-30s", get_full_name(), trans.convert2string(), "wb_transaction MISMATCH!");
      end
   endfunction

endclass
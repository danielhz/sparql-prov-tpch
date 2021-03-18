#!/usr/bin/env ruby
# frozen_string_literal: true

if ARGV.size != 1
  warn 'Usage: tbl_to_rdf.rb <dir>'
  exit 1
end

# Translator from TBL to RDF.
class DataTranslator
  # Get an RDF term from a text value.
  def rdf_term_from_text(value)
    "\"#{value}\""
  end

  # Get an RDF term from an int value.
  def rdf_term_from_int(value)
    "\"#{value}\"^^xsd:integer"
  end

  # Get an RDF term from a decimal value.
  def rdf_term_from_decimal(value)
    "\"#{value}\"^^xsd:decimal"
  end

  # Get an RDF term from a date value.
  def rdf_term_from_date(value)
    "\"#{value}\"^^xsd:date"
  end

  # Get an RDF term from a region value.
  def rdf_term_from_region(value)
    "<Region/#{value}>"
  end

  # Get an RDF term from a region value.
  def rdf_term_from_nation(value)
    "<Nation/#{value}>"
  end

  # Get an RDF term from a part value.
  def rdf_term_from_part(value)
    "<Part/#{value}>"
  end

  # Get an RDF term from a supplier value.
  def rdf_term_from_supplier(value)
    "<Supplier/#{value}>"
  end

  # Get an RDF term from a customer value.
  def rdf_term_from_customer(value)
    "<Customer/#{value}>"
  end

  # Get an RDF term from a order value.
  def rdf_term_from_order(value)
    "<Order/#{value}>"
  end
end

# Translator for parts from TBL to RDF.
class PartTranslator < DataTranslator
  def parse_row(row)
    "<Part/#{row[0]}> a <Part> ;\n" \
    "    <p_name> #{rdf_term_from_text(row[1])} ;\n" \
    "    <p_mfgr> #{rdf_term_from_text(row[2])} ;\n" \
    "    <p_brand> #{rdf_term_from_text(row[3])} ;\n" \
    "    <p_type> #{rdf_term_from_text(row[4])} ;\n" \
    "    <p_size> #{rdf_term_from_int(row[5])} ;\n" \
    "    <p_container> #{rdf_term_from_text(row[6])} ;\n" \
    "    <p_retailprice> #{rdf_term_from_decimal(row[7])} ;\n" \
    "    <p_comment> #{rdf_term_from_text(row[8])} .\n"
  end
end

# Translator for regions from TBL to RDF.
class RegionTranslator < DataTranslator
  def parse_row(row)
    "<Region/#{row[0]}> a <Region> ;\n" \
    "    <r_name> #{rdf_term_from_text(row[1])} ;\n" \
    "    <r_comment> #{rdf_term_from_text(row[2])} .\n"
  end
end

# Translator for nations from TBL to RDF.
class NationTranslator < DataTranslator
  def parse_row(row)
    "<Nation/#{row[0]}> a <Nation> ;\n" \
    "    <n_name> #{rdf_term_from_text(row[1])} ;\n" \
    "    <n_region> #{rdf_term_from_region(row[2])} ;\n" \
    "    <n_comment> #{rdf_term_from_text(row[3])} .\n"
  end
end

# Translator for suppliers from TBL to RDF.
class SupplierTranslator < DataTranslator
  def parse_row(row)
    "<Supplier/#{row[0]}> a <Supplier> ;\n" \
    "    <s_name> #{rdf_term_from_text(row[1])} ;\n" \
    "    <s_address> #{rdf_term_from_text(row[2])} ;\n" \
    "    <s_nation> #{rdf_term_from_nation(row[3])} ;\n" \
    "    <s_phone> #{rdf_term_from_text(row[4])} ;\n" \
    "    <s_acctbal> #{rdf_term_from_decimal(row[5])} ;\n" \
    "    <s_comment> #{rdf_term_from_text(row[6])} .\n"
  end
end

# Translator for partsupps from TBL to RDF.
class PartSuppTranslator < DataTranslator
  def parse_row(row)
    "<PartSupp/#{row[0]}/#{row[1]}> a <PartSupp> ;\n" \
    "    <ps_part> #{rdf_term_from_part(row[0])} ;\n" \
    "    <ps_supp> #{rdf_term_from_supplier(row[1])} ;\n" \
    "    <ps_availqty> #{rdf_term_from_int(row[2])} ;\n" \
    "    <ps_supplycost> #{rdf_term_from_decimal(row[3])} ;\n" \
    "    <ps_comment> #{rdf_term_from_text(row[4])} .\n"
  end
end

# Translator for customers from TBL to RDF.
class CustomerTranslator < DataTranslator
  def parse_row(row)
    "<Customer/#{row[0]}> a <Customer> ;\n" \
    "    <c_name> #{rdf_term_from_text(row[1])} ;\n" \
    "    <c_address> #{rdf_term_from_text(row[2])} ;\n" \
    "    <c_nation> #{rdf_term_from_nation(row[3])} ;\n" \
    "    <c_phone> #{rdf_term_from_text(row[4])} ;\n" \
    "    <c_acctbal> #{rdf_term_from_decimal(row[5])} ;\n" \
    "    <c_mktsegment> #{rdf_term_from_text(row[6])} ;\n" \
    "    <c_comment> #{rdf_term_from_text(row[7])} .\n"
  end
end

# Translator for orders from TBL to RDF.
class OrderTranslator < DataTranslator
  def parse_row(row)
    "<Order/#{row[0]}> a <Order> ;\n" \
    "    <o_cust> #{rdf_term_from_customer(row[1])} ;\n" \
    "    <o_orderstatus> #{rdf_term_from_text(row[2])} ;\n" \
    "    <o_totalprice> #{rdf_term_from_decimal(row[3])} ;\n" \
    "    <o_orderdate> #{rdf_term_from_date(row[4])} ;\n" \
    "    <o_orderpriority> #{rdf_term_from_text(row[5])} ;\n" \
    "    <o_clerk> #{rdf_term_from_text(row[6])} ;\n" \
    "    <o_shippriority> #{rdf_term_from_int(row[7])} ;\n" \
    "    <o_comment> #{rdf_term_from_text(row[8])} .\n"
  end
end

# Translator for lineitems from TBL to RDF.
class LineItemTranslator < DataTranslator
  def parse_row(row)
    "<LineItem/#{row[0]}/#{row[3]}> a <LineItem> ;\n" \
    "    <l_order> #{rdf_term_from_order(row[0])} ;\n" \
    "    <l_part> #{rdf_term_from_part(row[1])} ;\n" \
    "    <l_supp> #{rdf_term_from_supplier(row[2])} ;\n" \
    "    <l_linenumber> #{rdf_term_from_int(row[3])} ;\n" \
    "    <l_quantity> #{rdf_term_from_decimal(row[4])} ;\n" \
    "    <l_extendedprice> #{rdf_term_from_decimal(row[5])} ;\n" \
    "    <l_discount> #{rdf_term_from_decimal(row[6])} ;\n" \
    "    <l_tax> #{rdf_term_from_decimal(row[7])} ;\n" \
    "    <l_returnflag> #{rdf_term_from_text(row[8])} ;\n" \
    "    <l_linestatus> #{rdf_term_from_text(row[9])} ;\n" \
    "    <l_shipdate> #{rdf_term_from_date(row[10])} ;\n" \
    "    <l_commitdate> #{rdf_term_from_date(row[11])} ;\n" \
    "    <l_receiptdate> #{rdf_term_from_date(row[12])} ;\n" \
    "    <l_shipinstruct> #{rdf_term_from_text(row[13])} ;\n" \
    "    <l_shipmode> #{rdf_term_from_text(row[14])} ;\n" \
    "    <l_comment> #{rdf_term_from_text(row[15])} .\n"
  end
end

{
  'part' => PartTranslator,
  'region' => RegionTranslator,
  'nation' => NationTranslator,
  'supplier' => SupplierTranslator,
  'partsupp' => PartSuppTranslator,
  'customer' => CustomerTranslator,
  'orders' => OrderTranslator,
  'lineitem' => LineItemTranslator
}.each do |name, translator_class|
  Dir[File.join(ARGV[0], '**', "#{name}.tbl")].sort.each do |tbl_file_name|
    translator = translator_class.new
    ttl_file_name = tbl_file_name.sub(/\.tbl$/, '.ttl')
    warn "Proccessing #{tbl_file_name} -> #{ttl_file_name}"

    File.open(ttl_file_name, 'w') do |out_file|
      out_file.puts '@base <http://example.org/> .'
      out_file.puts '@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .'
      File.foreach(tbl_file_name) do |row|
        out_file.puts translator.parse_row(row.split('|'))
      end
    end
  end
end

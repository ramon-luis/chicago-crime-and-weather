package ramonlrodriguez.crimeTopology;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import org.apache.commons.lang.StringUtils;
import org.apache.hadoop.hbase.HBaseConfiguration;
import org.apache.hadoop.hbase.TableName;
import org.apache.hadoop.hbase.client.Connection;
import org.apache.hadoop.hbase.client.ConnectionFactory;
import org.apache.hadoop.hbase.client.Put;
import org.apache.hadoop.hbase.client.Table;
import org.apache.hadoop.hbase.util.Bytes;

import backtype.storm.LocalCluster;
import backtype.storm.StormSubmitter;
import backtype.storm.generated.AlreadyAliveException;
import backtype.storm.generated.AuthorizationException;
import backtype.storm.generated.InvalidTopologyException;
import backtype.storm.spout.SchemeAsMultiScheme;
import backtype.storm.task.TopologyContext;
import backtype.storm.topology.BasicOutputCollector;
import backtype.storm.topology.OutputFieldsDeclarer;
import backtype.storm.topology.TopologyBuilder;
import backtype.storm.topology.base.BaseBasicBolt;
import backtype.storm.tuple.Fields;
import backtype.storm.tuple.Tuple;
import backtype.storm.tuple.Values;
import backtype.storm.utils.Utils;
import storm.kafka.KafkaSpout;
import storm.kafka.SpoutConfig;
import storm.kafka.StringScheme;
import storm.kafka.ZkHosts;

public class CrimeTopology {

	static class FilterCrimeBolt extends BaseBasicBolt {
		Pattern yearPattern;
		Pattern crimePattern;
		@Override
		public void prepare(Map stormConf, TopologyContext context) {
			yearPattern = Pattern.compile("<year>K(20d{2})</year>");
			crimePattern = Pattern.compile("<crime>([^<]*)</crime>");
			super.prepare(stormConf, context);
		}

		@Override
		public void execute(Tuple tuple, BasicOutputCollector collector) {
			String report = tuple.getString(0);
			Matcher yearMatcher = yearPattern.matcher(report);
			if(!yearMatcher.find()) {
				return;
			}
			Matcher crimeMatcher = crimePattern.matcher(report);
			if(!crimeMatcher.find()) {
				return;
			}
			collector.emit(new Values(yearMatcher.group(1), crimeMatcher.group(1)));
		}

		@Override
		public void declareOutputFields(OutputFieldsDeclarer declarer) {
			declarer.declare(new Fields("year", "crime"));
		}

	}

	static class ExtractCrimeBolt extends BaseBasicBolt {

		@Override
		public void execute(Tuple input, BasicOutputCollector collector) {
			int year = input.getIntegerByField("year");
			String crime = input.getStringByField("crime");
			
			boolean isGoodWeather = crime.contains("isGoodWeather");
			
			boolean isCrime = true;
			boolean isDomestic = crime.contains("isDomestic");
			boolean isArrest = crime.contains("isArrest");
			boolean isViolentCrime = crime.contains("isViolentCrime");
			boolean isSexualAssault = crime.contains("isSexualAssault");
			boolean isBurglary = crime.contains("isBurglary");
			boolean isVandalism = crime.contains("isVandalism");
			boolean isProstitution = crime.contains("isProstitution");
			
			boolean isGoodWeatherCrime = (isGoodWeather && isCrime);
			boolean isGoodWeatherDomestic = (isGoodWeather && isDomestic);
			boolean isGoodWeatherArrest = (isGoodWeather && isArrest);
			boolean isGoodWeatherViolentCrime = (isGoodWeather && isViolentCrime);
			boolean isGoodWeatherSexualAssault = (isGoodWeather && isSexualAssault);
			boolean isGoodWeatherBurglary = (isGoodWeather && isBurglary);
			boolean isGoodWeatherVandalism = (isGoodWeather && isVandalism);
			boolean isGoodWeatherProstitution = (isGoodWeather && isProstitution);
			
			
			collector.emit(new Values(
					year, isCrime, isGoodWeatherCrime, isDomestic, isGoodWeatherDomestic,
					isArrest, isGoodWeatherArrest, isViolentCrime, isGoodWeatherViolentCrime,
					isSexualAssault, isGoodWeatherSexualAssault, isBurglary, isGoodWeatherBurglary,
					isVandalism, isGoodWeatherVandalism, isProstitution, isGoodWeatherProstitution));
		}

		@Override
		public void declareOutputFields(OutputFieldsDeclarer declarer) {
			declarer.declare(new Fields(
					"year", "isCrime", "isGoodWeatherCrime", "isDomestic", "isGoodWeatherDomestic", 
					"isArrest", "isGoodWeatherArrest", "isViolentCrime", "isGoodWeatherViolentCrime", 
					"isSexualAssault","isGoodWeatherSexualAssault", "isBurglary", "isGoodWeatherBurglary", 
					"isVandalism", "isGoodWeatherVandalism", "isProstitution", "isGoodWeatherProstitution"));
		}

	}

	static class UpdateCurrentCrimeBolt extends BaseBasicBolt {
		private org.apache.hadoop.conf.Configuration conf;
		private Connection hbaseConnection;
		@Override
		public void prepare(Map stormConf, TopologyContext context) {
			try {
				conf = HBaseConfiguration.create();
//			    conf.set("hbase.zookeeper.property.clientPort", "2181");
			    conf.set("hbase.zookeeper.property.clientPort", "6667");
			    conf.set("hbase.zookeeper.quorum", StringUtils.join((List<String>)(stormConf.get("storm.zookeeper.servers")), ","));
			    String znParent = (String)stormConf.get("zookeeper.znode.parent");
			    if(znParent == null)
			    	znParent = new String("/hbase");
				conf.set("zookeeper.znode.parent", znParent);
				hbaseConnection = ConnectionFactory.createConnection(conf);
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			super.prepare(stormConf, context);
		}

		@Override
		public void cleanup() {
			try {
				hbaseConnection.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			// TODO Auto-generated method stub
			super.cleanup();
		}

		@Override
		public void execute(Tuple input, BasicOutputCollector collector) {
			try {
				Table table = hbaseConnection.getTable(TableName.valueOf("ramonlrodriguez_current_crime"));
				
				Put put = new Put(Bytes.toBytes(input.getIntegerByField("year")));
				
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeather"), Bytes.toBytes(input.getBooleanByField("isGoodWeather")));

				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isCrime"), Bytes.toBytes(input.getBooleanByField("isCrime")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isArrest"), Bytes.toBytes(input.getBooleanByField("isArrest")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isDomestic"), Bytes.toBytes(input.getBooleanByField("isDomestic")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isViolentCrime"), Bytes.toBytes(input.getBooleanByField("isViolentCrime")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isSexualAssault"), Bytes.toBytes(input.getBooleanByField("isSexualAssault")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isBurglary"), Bytes.toBytes(input.getBooleanByField("isBurglary")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isVandalism"), Bytes.toBytes(input.getBooleanByField("isVandalism")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isProstitution"), Bytes.toBytes(input.getBooleanByField("isProstitution")));
		
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherCrime"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherCrime")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherArrest"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherArrest")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherDomestic"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherDomestic")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherViolentCrime"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherViolentCrime")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherSexualAssault"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherSexualAssault")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherBurglary"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherBurglary")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherVandalism"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherVandalism")));
				put.addColumn(Bytes.toBytes("crime"), Bytes.toBytes("isGoodWeatherProstitution"), Bytes.toBytes(input.getBooleanByField("isGoodWeatherProstitution")));
				
				table.put(put);
				table.close();
			} catch (IOException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}

		@Override
		public void declareOutputFields(OutputFieldsDeclarer declarer) {
			// TODO Auto-generated method stub

		}

	}

	public static void main(String[] args) throws AlreadyAliveException, InvalidTopologyException, AuthorizationException {
		Map stormConf = Utils.readStormConfig();
		String zookeepers = StringUtils.join((List<String>)(stormConf.get("storm.zookeeper.servers")), ",");
		System.out.println(zookeepers);
		ZkHosts zkHosts = new ZkHosts(zookeepers);
		
		SpoutConfig kafkaConfig = new SpoutConfig(zkHosts, "ramonlrodriguez-crime-events", "/ramonlrodriguez-crime-events","crime_id");
		kafkaConfig.scheme = new SchemeAsMultiScheme(new StringScheme());
		// kafkaConfig.zkServers = (List<String>)stormConf.get("storm.zookeeper.servers");
		kafkaConfig.zkRoot = "/ramonlrodriguez-crime-events";
		// kafkaConfig.zkPort = 2181;
		KafkaSpout kafkaSpout = new KafkaSpout(kafkaConfig);

		TopologyBuilder builder = new TopologyBuilder();

		builder.setSpout("raw-crime-events", kafkaSpout, 1);
		builder.setBolt("filter-crime", new FilterCrimeBolt(), 1).shuffleGrouping("raw-crime-events");
		builder.setBolt("extract-crime", new ExtractCrimeBolt(), 1).shuffleGrouping("filter-crime");
		builder.setBolt("update-current-crime", new UpdateCurrentCrimeBolt(), 1).fieldsGrouping("extract-crime", new Fields("year"));


		Map conf = new HashMap();
		conf.put(backtype.storm.Config.TOPOLOGY_WORKERS, 2);

		if (args != null && args.length > 0) {
			StormSubmitter.submitTopology(args[0], conf, builder.createTopology());
		}   else {
			conf.put(backtype.storm.Config.TOPOLOGY_DEBUG, true);
			LocalCluster cluster = new LocalCluster(zookeepers, 2181L);
			cluster.submitTopology("ramonlrodriguez-crime-topology", conf, builder.createTopology());
		} 
	} 
}

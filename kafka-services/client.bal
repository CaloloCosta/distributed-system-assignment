// 1 - client service puslibshes the get-table message
// 2 - client service subscribes to the found-table

import wso2/kafka;
import ballerina/encoding;
import ballerina/io;

// client producer
kafka:ProducerConfig producerConfigs = {
    bootstrapServers: "localhost:9092",
    clientID: "client-producer",
    acks: "all",
    noRetries: 3
};
kafka:SimpleProducer kafkaProducer = new(producerConfigs);
// client consumer
kafka:ConsumerConfig consumerConfig = {
    bootstrapServers: "localhost:9092, localhost:9093",
    groupId: "client",
    topics: ["found-table", "get-menu"],
    pollingInterval: 1000
};
listener kafka:SimpleConsumer clientConsumer = new(consumerConfig);
service kafkaService on clientConsumer{
    resource function onMessage(kafka:SimpleConsumer simpleConsumer, kafka:ConsumerRecord[] records){
        foreach var entry in records {
            byte[] sMsg = entry.value;
            string msg = encoding:byteArrayToString(sMsg);
            match(entry.topic){
                "found-table" => {
                    //io:println("Topic: ", entry.topic,"; Received Message: ",msg);
                    io:StringReader sr = new (msg, encoding = "UTF-8");
                    json|error j =  sr.readJson();
                    if(j is json){
                        if(j.Message != null){
                            io:println(j.Message);
                            return;
                        }
                        else{
                            io:println("Communicate with table");
                            tableHandler();
                        }
                    }
                }
                "get-menu" => {
                    io:println("\n",msg,"\n");
                    tableHandler();
                }
            }
            
        }
    }
}


public function main(){
    clientGetTable();
    return;

}

function clientGetTable(){
    string bId = io:readln("Enter your booking id please: ");
    if(bId != ""){
        string bookingId = bId;
        clientPublisher("get-table",bookingId);
    }

}

function tableHandler(){
    io:println("Welcome to your table");
    // "create-order", "leave-table", "request-bill", "do-payment", "request-menu"
    io:println("1 - Menu\n2-Order\n3-request-bill\n4-pay\n5-Leave");
    boolean b = true;
    while(b){
        var option = io:readln("Option: ");
        match(option){
            "1" => {
                clientPublisher("request-menu","");
            }
            "2" => {
                io:println("Order templete: itemName quantity, itemName quantity....");
                string orderMsg = io:readln("What will you order:\n");
                clientPublisher("create-order",orderMsg);
                io:println("Your order is being processed....");
            }
        }
    }
}

function clientPublisher(string topic, string msg){
    byte[] sMsg = msg.toByteArray("UTF-8");
    var publish = kafkaProducer->send(sMsg, topic, partition = 0);
}

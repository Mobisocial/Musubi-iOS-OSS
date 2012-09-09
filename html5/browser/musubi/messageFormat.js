Musubi.MessageFormat = function() {
};

Musubi.MessageFormat.prototype.consumeLength = function(data, ptr) {
	ptr[0] += 2;
	return data[ptr[0] - 2] * 256 + data[ptr[0] - 1];
};

Musubi.MessageFormat.prototype.consumeLengthBigEndian32 = function(data, ptr) {
	ptr[0] += 4;
	return data[ptr[0] - 4] * 1024 + data[ptr[0] - 3] * 512 + data[ptr[0] - 2] * 256 + data[ptr[0] - 1];
};

Musubi.MessageFormat.prototype.consumeSegment = function(data, ptr) {
	len = this.consumeLength(data, ptr)
	ptr[0] += len
	return data.slice(ptr[0] - len, ptr[0]);
};

Musubi.MessageFormat.prototype.consumeBigSegment = function(data, ptr) {
	len = this.consumeLengthBigEndian32(data, ptr)
	ptr[0] += len
	return data.slice(ptr[0] - len, ptr[0]);
};

Musubi.MessageFormat.prototype.personIdForKey = function(key) {
	
	return Crypto.SHA1(key).substring(0,10);
}

Musubi.MessageFormat.prototype.unpackMessage = function(data) {
	json = JSON.parse(data);
	
	var msg = new SocialKit.SignedMessage();
	msg.timestamp = json["timestamp"];
	msg.feedName = json["feedName"];
	msg.appId = json["appId"];
	msg.parentHash = json["parentHash"];
	msg.obj = {type: json["type"], data: {}};
	for (key in json) {
		if (key != "timestamp" && key != "feedName" && key != "appId" && key != "type" && key != "target_relation" && key != "target_hash") {
			msg.obj.data[key] = json[key];
		}
	}
	
	return msg;
};

Musubi.MessageFormat.prototype.decode = function(encoded, keyPair) {
	var data = encoded.message;
	var ptr = [0];
	
	var senderKey = this.consumeSegment(data, ptr);
	var numberOfKeys = this.consumeLength(data, ptr);
	
	var myPersonId = this.personIdForKey(Crypto.util.base64ToBytes(keyPair.publicKeyString));
	
	var recipients = [];
	
	for (var i=0; i<numberOfKeys; i++) {
		
		var personId = Crypto.charenc.UTF8.bytesToString(this.consumeSegment(data, ptr));
		var encryptedAesKey = this.consumeSegment(data, ptr);
		
		recipients.push(personId);
		
		if (personId == myPersonId) {
			myAesKey = encryptedAesKey;
		}
	}
	
	if (typeof myAesKey == "undefined") {
		throw "Message does not contain my person id"
	}
	
	var encryptedAesKey = Crypto.util.bytesToHex(myAesKey);
	var aes = keyPair.decrypt(encryptedAesKey);
	var aesIV = this.consumeSegment(data, ptr);
	var cyphered = this.consumeBigSegment(data, ptr);
	var plain = Crypto.AES.decrypt(cyphered, aes, {iv: aesIV, mode: new Crypto.mode.CBC(Crypto.pad.pkcs7), asBytes: true})
	
	var msg = this.unpackMessage(Crypto.charenc.UTF8.bytesToString(plain));
	msg.sender = new SocialKit.User({name: "", id: Crypto.util.bytesToBase64(senderKey)});
	
	return msg;
};


Musubi.messageFormat = new Musubi.MessageFormat();
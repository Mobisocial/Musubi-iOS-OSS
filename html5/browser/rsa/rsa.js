// RSA, a suite of routines for performing RSA public-key computations in
// JavaScript.
//
// Requires BigInt.js and Barrett.js.
//
// Copyright 1998-2005 David Shapiro.
//
// You may use, re-use, abuse, copy, and modify this code to your liking, but
// please keep this header.
//
// Thanks!
// 
// Dave Shapiro
// dave@ohdave.com 

function RSAKeyPair(publicKey, privateKey)
{
	var publicKeyData = new ASN1Data(Crypto.charenc.Binary.bytesToString(Crypto.util.base64ToBytes(publicKey)));
	var modulus = Crypto.util.bytesToHex(Crypto.charenc.Binary.stringToBytes(publicKeyData.data[0][1][0][0]).splice(1));
	var encryptionExponent = Crypto.util.bytesToHex(Crypto.charenc.Binary.stringToBytes(publicKeyData.data[0][1][0][1]));
	var decryptionExponent = null;
	
	if (privateKey) {
		var privateKeyData = new ASN1Data(Crypto.charenc.Binary.bytesToString(Crypto.util.base64ToBytes(privateKey)));
		
		var m = Crypto.util.bytesToHex(Crypto.charenc.Binary.stringToBytes(privateKeyData.data[0][1]).splice(1));
		var e = Crypto.util.bytesToHex(Crypto.charenc.Binary.stringToBytes(privateKeyData.data[0][2]));
		decryptionExponent = Crypto.util.bytesToHex(Crypto.charenc.Binary.stringToBytes(privateKeyData.data[0][3]));
		
		if (m != modulus) {
			throw "Modulus of public and private key don't match";
		} else if (e != encryptionExponent) {
			throw "Public exponent of public and private key don't match";
		}
	}
	
	if (modulus.length < 1024) {
		setMaxDigits((modulus.length / 32) * 19)
	} else if (modulus.length == 1024) {
		setMaxDigits(130);
	} else if (modulus.length == 1024) {
		setMaxDigits(260);
	}
	
	this.e = biFromHex(encryptionExponent);
	if (decryptionExponent)
		this.d = biFromHex(decryptionExponent);
	this.m = biFromHex(modulus);
	// We can do two bytes per digit, so
	// chunkSize = 2 * (number of digits in modulus - 1).
	// Since biHighIndex returns the high index, not the number of digits, 1 has
	// already been subtracted.
	this.chunkSize = 2 * biHighIndex(this.m);
	this.radix = 16;
	this.barrett = new BarrettMu(this.m);
	
	this.publicKeyString = publicKey;
}

RSAKeyPair.prototype.encrypt = function(s)
	// Altered by Rob Saunders (rob@robsaunders.net). New routine pads the
	// string after it has been converted to an array. This fixes an
	// incompatibility with Flash MX's ActionScript.
{
	var a = new Array();
	var sl = s.length;
	var i = 0;
	while (i < sl) {
		a[i] = s.charCodeAt(i);
		i++;
	}

	while (a.length % this.chunkSize != 0) {
		a[i++] = 0;
	}

	var al = a.length;
	var result = "";
	var j, k, block;
	for (i = 0; i < al; i += this.chunkSize) {
		block = new BigInt();
		j = 0;
		for (k = i; k < i + this.chunkSize; ++j) {
			block.digits[j] = a[k++];
			block.digits[j] += a[k++] << 8;
		}
		var crypt = this.barrett.powMod(block, this.e);
		var text = this.radix == 16 ? biToHex(crypt) : biToString(crypt, this.radix);
		result += text + " ";
	}
	return result.substring(0, result.length - 1); // Remove last space.
}

RSAKeyPair.prototype.decrypt = function(s)
{
	var blocks = s.split(" ");
	var result = [];
	var i, j, block;
	for (i = 0; i < blocks.length; ++i) {
		var bi;
		if (this.radix == 16) {
			bi = biFromHex(blocks[i]);
		}
		else {
			bi = biFromString(blocks[i], this.radix);
		}
		block = this.barrett.powMod(bi, this.d);
		
		for (j = 0; j <= biHighIndex(block); ++j) {
			result.unshift(block.digits[j] & 255);
			result.unshift(block.digits[j] >> 8);
		}
	}
	// Remove trailing null, if any.
//	if (result.charCodeAt(result.length - 1) == 0) {
//		result = result.substring(0, result.length - 1);
//	}
	return result;
}

var ASN1Data = function($data) {
    this.error = false;
    this.parse = function($data) {
        if (!$data) {
            this.error = true;
            return null;
        }
        var $result = [];
        while($data.length > 0) {
            // get the tag
            var $tag = $data.charCodeAt(0);
            $data = $data.substr(1);
            // get length
            var $length = 0;
            // ignore any null tag
            if (($tag & 31) == 0x5) $data = $data.substr(1);
            else {
                if ($data.charCodeAt(0) & 128) {
                    var $lengthSize = $data.charCodeAt(0) & 127;
                    $data = $data.substr(1);
                    if($lengthSize > 0) $length = $data.charCodeAt(0);
                    if($lengthSize > 1)    $length = (($length << 8) | $data.charCodeAt(1));
                    if($lengthSize > 2) {
                        this.error = true;
                        return null;
                    }
                    $data = $data.substr($lengthSize);
                } else {
                    $length = $data.charCodeAt(0);
                    $data = $data.substr(1);
                }
            }
            // get value
            var $value = "";
            if($length) {
                if ($length > $data.length){
                    this.error = true;
                    return null;
                }
                $value = $data.substr(0, $length);
                $data = $data.substr($length);
            }
            if ($tag & 32)
                $result.push(this.parse($value)); // sequence
            else
                $result.push(this.value(($tag & 128) ? 4 : ($tag & 31), $value));
        }
        return $result;
    };
    this.value = function($tag, $data) {
        if ($tag == 1)
            return $data ? true : false;
        else if ($tag == 2) //integer
            return $data;
        else if ($tag == 3) //bit string
            return this.parse($data.substr(1));
        else if ($tag == 5) //null
            return null;
        else if ($tag == 6){ //ID
            var $res = [];
            var $d0 = $data.charCodeAt(0);
            $res.push(Math.floor($d0 / 40));
            $res.push($d0 - $res[0]*40);
            var $stack = [];
            var $powNum = 0;
            var $i;
            for($i=1;$i<$data.length;$i++){
                var $token = $data.charCodeAt($i);
                $stack.push($token & 127);
                if ( $token & 128 )
                    $powNum++;
                else {
                    var $j;
                    var $sum = 0;
                    for($j=0;$j<$stack.length;$j++)
                        $sum += $stack[$j] * Math.pow(128, $powNum--);
                    $res.push($sum);
                    $powNum = 0;
                    $stack = [];
                }
            }
            return $res.join(".");
        }
        return null;
    }
    this.data = this.parse($data);
};


var RSA = {
    getPublicKey: function($pem) {
        if($pem.length<50) return false;
        if($pem.substr(0,26)!="-----BEGIN PUBLIC KEY-----") return false;
        $pem = $pem.substr(26);
        if($pem.substr($pem.length-24)!="-----END PUBLIC KEY-----") return false;
        $pem = $pem.substr(0,$pem.length-24);
        $pem = new ASN1Data(Base64.decode($pem));
        if($pem.error) return false;
        $pem = $pem.data;
        if($pem[0][0][0]=="1.2.840.113549.1.1.1")
            return new RSAPublicKey($pem[0][1][0][0], $pem[0][1][0][1]);
        return false;
    },
    encrypt: function($data, $pubkey) {
        if (!$pubkey) return false;
        $data = this.pkcs1pad2($data,($pubkey.modulus.bitLength()+7)>>3);
        if(!$data) return false;
        $data = $data.modPowInt($pubkey.encryptionExponent, $pubkey.modulus);
        if(!$data) return false;
        $data = $data.toString(16);
        return Base64.encode(Hex.decode($data));
    },
    pkcs1pad2: function($data, $keysize) {
        if($keysize < $data.length + 11)
            return null;
        var $buffer = [];
        var $i = $data.length - 1;
        while($i >= 0 && $keysize > 0)
            $buffer[--$keysize] = $data.charCodeAt($i--);
        $buffer[--$keysize] = 0;
        while($keysize > 2)
            $buffer[--$keysize] = Math.floor(Math.random()*254) + 1;
        $buffer[--$keysize] = 2;
        $buffer[--$keysize] = 0;
        return new BigInteger($buffer);
    }
}
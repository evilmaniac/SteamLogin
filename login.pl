#!/usr/bin/perl

# eM-SteamLogin
# Written by evilmaniac
# http://www.evilmania.net

# Log:
# Valve server returns "Invalid Login" error
# key generation may be invalid.
# O- Key generated has been confirmed to be constant
#    when the modulus and exponent remain constant

use warnings;
use bigint qw/hex oct/;
use JSON; # libjson-perl
use LWP::UserAgent;

use MIME::Base64;
use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::Bignum;

my $sUsername = '';
my $sPassword = '';
my %sJSON;

my $sUserAgent = LWP::UserAgent->new();
my $sResponse   = $sUserAgent->post('https://steamcommunity.com/login/getrsakey/', {'username' => $sUsername});
if($sResponse->is_success()){
	%sJSON = %{ decode_json($sResponse->decoded_content) };		
}

my $modulus 	= Crypt::OpenSSL::Bignum->new_from_hex( $sJSON{'publickey_mod'} );
my $exponent 	= Crypt::OpenSSL::Bignum->new_from_hex( $sJSON{'publickey_exp'} );
my $rsa = Crypt::OpenSSL::RSA->new_key_from_parameters($modulus, $exponent);
$rsa->use_pkcs1_padding();

my $sEncryptedPassword = encode_base64($rsa->encrypt($sPassword));

my %hPayload  = (
		'redir' 	=> 'http://steamcommunity.com/actions/RedirectToHome',
		'password'	=> $sEncryptedPassword,
		'username'	=> $sUsername,
		'emailauth'	=> '',
		'captcha_text'	=> '',
		'emailsteamid'	=> '',
		'rsatimestamp'	=> $sJSON{'timestamp'}
	     );

$sUserAgent = LWP::UserAgent->new();
$sResponse   = $sUserAgent->post('https://steamcommunity.com/login/dologin/', \%hPayload);
if($sResponse->is_success()){
	print $sResponse->decoded_content;
}

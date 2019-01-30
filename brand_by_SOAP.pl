#!/usr/bin/perl
use strict;
use warnings;
use feature qw(say);

# ------
# File   : getBrandByName.pl 
# History: 25-Jan-2019 Zhaozhi created the File
# ------
# This file take Druglist from file and get Brand Name of that list
# Input  : ~/Desktop/druglist.txt
# Output : ~/Desktop/SOAP_time_Brand.txt
# ------

use feature qw(say);
use SOAP::Lite + trace => qw(debug);
use Data::Dumper;

my ($weekDay, $month, $mday, $time, $year) = split(" ",localtime());
my $outfile   = ">/Users/zhaozhili/Desktop/SOAP_$month\_$mday\_$year\_Brand";
my $infile    = "/Users/zhaozhili/Desktop/druglist.txt";
open(my $InFh, $infile) or die $!;
open(my $OutFh, $outfile) or die $!;
say $OutFh join("\t", "drug", "brand_name");                          # Print colname

# Setup service
my $WSDL      = "https://www.ebi.ac.uk/webservices/chebi/2.0/webservice?wsdl";
my $nameSpace = "https://www.ebi.ac.uk/webservices/chebi";
my $soap = SOAP::Lite
   -> uri($nameSpace)
   -> proxy($WSDL);

# Setup method 
my $getLiteEntity = SOAP::Data->name('getLiteEntity')                 # Set method and params
                              ->attr({xmlns => $nameSpace});
my $getEntity     = SOAP::Data->name('getCompleteEntity')
                              ->attr({xmlns => $nameSpace});

my @drugs = <$InFh>;
while (my $drug = <@drugs>){
    my (@params1, ,@params2, $liteEntity, $chebiId, $entity, @results,) = undef;
    chomp $drug;
    $drug = lc($drug);
    # Retrieve ChEBI Id
    @params1  = ( SOAP::Data->name(search => $drug),     
                    SOAP::Data->name(searchCategory => 'CHEBI NAME'),
                    SOAP::Data->name(stars => 'ALL')
                    );
    $liteEntity = $soap->call($getLiteEntity => @params1);             # Call method
    $chebiId    = $liteEntity->valueof('//ListElement//chebiId');           
    # Retrieve Brand Name

    @params2 = ( SOAP::Data->name(chebiId => $chebiId));
    $entity  = $soap->call($getEntity => @params2);
    @results = $entity->valueof('//Synonyms');
    foreach my $result (@results){
        if($result->{'type'} eq 'BRAND NAME'){
        say $OutFh join("\t", $drug, $result->{'data'});
        }
    }
}
close($InFh);
close($OutFh);

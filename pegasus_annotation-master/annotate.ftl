<?xml version="1.0" encoding="UTF-8"?>
<adag xmlns="http://pegasus.isi.edu/schema/DAX" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://pegasus.isi.edu/schema/DAX http://pegasus.isi.edu/schema/dax-3.3.xsd" version="3.3" name="${outputprefix}.annotate">
<!-- 
annotate v1
-->
<#assign startFile ="${start_file}"/>
<#assign filename ="${outputfolder}/${outputprefix}"/>
<#assign logfilename ="${outputfolder}/log/${outputprefix}"/>
	<executable name="javasnpeffrefs" namespace="annotate" version="${snpeff_ver}" arch="x86_64" installed="true">
		<pfn url="file://${java_binary}" site="condorpool"/>
	</executable>
	<executable name="javasnpsift" namespace="annotate" version="${snpeff_ver}" arch="x86_64" installed="true">
		<pfn url="file://${java_binary}" site="condorpool"/>
	</executable>

	<executable name="rm" namespace="annotate" version="4.0" arch="x86_64" installed="true">
		<pfn url="file:///bin/rm" site="condorpool"/>
	</executable>
	<executable name="sed" namespace="annotate" version="4.0" arch="x86_64" installed="true">
		<pfn url="file:///bin/sed" site="condorpool"/>
	</executable>
	<executable name="cp" namespace="annotate" version="4.0" arch="x86_64" installed="true">
		<pfn url="file:///bin/cp" site="condorpool"/>
	</executable>
	<executable name="perl" namespace="annotate" version="5.8.8" arch="x86_64" installed="true">
		<pfn url="file:///usr/bin/perl" site="condorpool"/>
	</executable>
        <executable name="curl" namespace="annotate" version="5.8.8" arch="x86_64" installed="true">
                <pfn url="file:///usr/bin/curl" site="condorpool"/>
        </executable>	

	<job id="${nodeprefix}_SNPEFF_refs" namespace="annotate" name="javasnpeffrefs" version="${snpeff_ver}">
	  <argument>
	    -Xmx8g
	    -Djava.io.tmpdir=${tempdir}
	    -jar ${snpeffjar} eff 
	    -c ${snpeffconfig} 
	    -ud 10 
	    -i vcf 
	    -o vcf 
	    -t hg19 
	    ${startFile}
	  </argument>
	  <profile namespace="condor" key="request_cpus">2</profile>
	  <stdout name="${filename}.snpEff.vcf" link="output"/>
	  <stderr name="${logfilename}.snpeff_ref_job.err" link="output"/>
	</job>
	
	<job id="${nodeprefix}_SNPSIFT_1kg" namespace="annotate" name="javasnpsift" version="${snpeff_ver}">
          <argument>
            -Xmx8g
            -Djava.io.tmpdir=${tempdir}
            -jar ${snpsiftjar} annotate
            -noId 
	    -info AF,AMR_AF,ASN_AF,AFR_AF,EUR_AF
	    ${kg_vcf}
	    ${filename}.snpEff.vcf
          </argument>
          <profile namespace="condor" key="request_cpus">2</profile>
          <stdout name="${filename}.snpEff.1kg.vcf" link="output"/>
          <stderr name="${logfilename}.snpsift_1kg_job.err" link="output"/>
        </job>
	
	<job id="${nodeprefix}_SED_a" namespace="annotate" name="sed" version="4.0">
          <argument>
            's/);AF=/);1kg_AF=/g' ${filename}.snpEff.1kg.vcf -i
          </argument>
          <profile namespace="condor" key="request_cpus">1</profile>
          <stderr name="${logfilename}.sedA_job.err" link="output"/>
        </job>
	
	<job id="${nodeprefix}_SED_b" namespace="annotate" name="sed" version="4.0">
          <argument>
	    's/##INFO=&lt;ID=ASN_AF,Number=1,Type=Float,Description="Allele Frequency for samples from ASN based on AC\/AN"&gt;/##INFO=&lt;ID=ASN_AF,Number=1,Type=Float,Description="Allele Frequency for samples from ASN based on AC\/AN"&gt;\r##INFO=&lt;ID=1kg_AF,Number=1,Type=Float,Description="Global Allele Frequency based on AC\/AN"&gt;/g' ${filename}.snpEff.1kg.vcf -i
	  </argument>
	  <profile namespace="condor" key="request_cpus">1</profile>
          <stderr name="${logfilename}.sedb_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SNPSIFT_evs" namespace="annotate" name="javasnpsift" version="${snpeff_ver}">
          <argument>
            -Xmx8g
            -Djava.io.tmpdir=${tempdir}
            -jar ${snpsiftjar} annotate
            -noId
            -info MAF
            ${evs_vcf}
            ${filename}.snpEff.1kg.vcf
          </argument>
          <profile namespace="condor" key="request_cpus">2</profile>
          <stdout name="${filename}.snpEff.1kg.evs.vcf" link="output"/>
          <stderr name="${logfilename}.snpsift_evs_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SNPSIFT_msigdb" namespace="annotate" name="javasnpsift" version="${snpeff_ver}">
          <argument>
            -Xmx8g
            -Djava.io.tmpdir=${tempdir}
            -jar ${snpsiftjar} geneSets
	    -v ${msigdb_file}
            ${filename}.snpEff.1kg.evs.vcf
          </argument>
          <profile namespace="condor" key="request_cpus">2</profile>
          <stdout name="${filename}.snpEff.1kg.evs.msigdb.vcf" link="output"/>
          <stderr name="${logfilename}.snpsift_msigdb_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SNPSIFT_dbnsfp" namespace="annotate" name="javasnpsift" version="${snpeff_ver}">
          <argument>
            -Xmx8g
            -Djava.io.tmpdir=${tempdir}
            -jar ${snpsiftjar} dbnsfp
	    -db ${dbnsfp_file}
	    -f SIFT_score,Polyphen2_HDIV_score,Polyphen2_HVAR_score,Uniprot_acc,Interpro_domain,SIFT_pred,Polyphen2_HDIV_pred,Polyphen2_HVAR_pred,LRT_pred,MutationAssessor_pred,GERP++_NR,GERP++_RS,phastCons100way_vertebrate,1000Gp1_AF,1000Gp1_AFR_AF,1000Gp1_EUR_AF,1000Gp1_AMR_AF,1000Gp1_ASN_AF,ESP6500_AA_AF,ESP6500_EA_AF
            ${filename}.snpEff.1kg.evs.msigdb.vcf
          </argument>
          <profile namespace="condor" key="request_cpus">2</profile>
          <stdout name="${filename}.snpEff.1kg.evs.msigdb.dbnsfp.vcf" link="output"/>
          <stderr name="${logfilename}.snpsift_dbnsfp_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SNPSIFT_chopAF" namespace="annotate" name="javasnpsift" version="${snpeff_ver}">
          <argument>
            -Xmx8g
            -Djava.io.tmpdir=${tempdir}
            -jar ${snpsiftjar} annotate
            -noId
            -info CHOP_AF
            ${chop_af}
            ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.vcf
          </argument>
          <profile namespace="condor" key="request_cpus">2</profile>
          <stdout name="${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.vcf" link="output"/>
          <stderr name="${logfilename}.snpsift_chop_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SED_GERP" namespace="annotate" name="sed" version="4.0">
          <argument>
	    's/dbNSFP_GERP++_/dbNSFP_GERP_/g' ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.vcf -i
          </argument>
          <profile namespace="condor" key="request_cpus">1</profile>
          <stderr name="${logfilename}.sedGERP_job.err" link="output"/>
        </job>

        <job id="${nodeprefix}_SED_NUM" namespace="annotate" name="sed" version="4.0">
          <argument>
	    's/Number=A,Type=Character/Number=.,Type=Character/g' ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.vcf -i
          </argument>
          <profile namespace="condor" key="request_cpus">1</profile>
          <stderr name="${logfilename}.sedGERP_job.err" link="output"/>
        </job>

	<job id="${nodeprefix}_add_cadd" namespace="annotate" name="perl" version="5.8.8">
	  <argument>
	    ${cadd_perl} ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.vcf ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.cadd.vcf ${cadd_file}
	  </argument>
	  <profile namespace="condor" key="request_cpus">1</profile>
	  <stderr name="${logfilename}.cadd.err" link="output"/>
	</job>



	<job id="${nodeprefix}_CLEANUP" namespace="annotate" name="rm" version="4.0">
		<argument>	
                        ${filename}.snpEff.vcf
                        ${filename}.snpEff.1kg.vcf
                        ${filename}.snpEff.1kg.evs.vcf
                        ${filename}.snpEff.1kg.evs.msigdb.vcf
                        ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.vcf		
                        ${filename}.snpEff.1kg.evs.msigdb.dbnsfp.chop.vcf
		</argument>
		<profile namespace="condor" key="request_cpus">1</profile>
		<stdout name="${logfilename}.cleanup_job.out" link="output"/>
                <stderr name="${logfilename}.cleanup_job.err" link="output"/>
	</job>
	
	
	<child ref="${nodeprefix}_SNPSIFT_1kg">
		<parent ref="${nodeprefix}_SNPEFF_refs"/>
	</child>
	<child ref="${nodeprefix}_SED_a">
		<parent ref="${nodeprefix}_SNPSIFT_1kg"/>
	</child>
	<child ref="${nodeprefix}_SED_b">
		<parent ref="${nodeprefix}_SED_a"/>
	</child>
	<child ref="${nodeprefix}_SNPSIFT_evs">
		<parent ref="${nodeprefix}_SED_b"/>
	</child>
	<child ref="${nodeprefix}_SNPSIFT_msigdb">
		<parent ref="${nodeprefix}_SNPSIFT_evs"/>
	</child>
	<child ref="${nodeprefix}_SNPSIFT_dbnsfp">
		<parent ref="${nodeprefix}_SNPSIFT_msigdb"/>
	</child>
	<child ref="${nodeprefix}_SNPSIFT_chopAF">
		<parent ref="${nodeprefix}_SNPSIFT_dbnsfp"/>
	</child>
	<child ref="${nodeprefix}_SED_GERP">
		<parent ref="${nodeprefix}_SNPSIFT_chopAF"/>
	</child>
	<child ref="${nodeprefix}_SED_NUM">
                <parent ref="${nodeprefix}_SED_GERP"/>
        </child>
	<child ref="${nodeprefix}_add_cadd">
		<parent ref="${nodeprefix}_SED_NUM"/>
	</child>
	<child ref="${nodeprefix}_CLEANUP">
		<parent ref="${nodeprefix}_add_cadd"/>
	</child>
</adag>

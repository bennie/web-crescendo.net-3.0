<?xml version="1.0"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/TR/WD-xsl">
<!-- This is the proper namespace declaration for XSLT but XSLT is not supported by IE5.5 without a MSXML SP3 or higher upgrade.
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
-->
<xsl:template match="/">
  
<html><head><title>Triggur Bingo</title></head>
<body bgcolor="#FFFFFF">
<xsl:for-each select="bingo/token">
<p><xsl:value-of select="value"/></p>
</xsl:for-each>

</body></html>
</xsl:template>
</xsl:stylesheet>

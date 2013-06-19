<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:r="http://www.fcla.edu/dls/md/daitss/">

  <xsl:output method="html"/>

  <!-- document -->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <!-- root element -->
  <xsl:template match="r:REPORT">
    <html>
      <head>
        <title>
          Florida Digital Archive Report
        </title>
        <style>
          /* page style */
          body {
          background-color: white;
          font-family: sans-serif;
          color: DarkBlue;
          margin:0em;
          padding:0em;
          width:auto }

          /* styles */
          p { color:Navy }

          a:link,
          a:visited {
          color: RoyalBlue }

          /* division related style */
          div.report {
          background-color: White;
          color: Green;
          margin:0em;
          padding:0em;
          width:auto}
          div.error {
          border: thin solid DarkSeaGreen;
          margin:.5em;
          padding:.5em;
          width:auto}

          div.ingest, div.refresh, div.d1refresh, div.withdrawal {
          margin:0.5em;
          padding:0.5em;
          width:auto}

          div.files {
          margin:0.5em;
          padding: 0.5em;
          width:auto}

          div.archivalAttributes,
          div.messageDigests,
          div.listing {
          margin:0.5em;
          padding:0.5em;
          width:auto}

          div.ftitle {
          font: bold small, Mono;
          margin-top: 1.5em;
          margin-bottom: 0.3em;
          }

          li.data {
          font: x-small, Mono;
          }

          /* table related style */
          th {
          color: Green;
          text-align: left;
          border-bottom: medium solid Green;
          font: bold small, Mono}

          td, li {
          color: DarkBlue;
          font: x-small, Mono;
          /*text-align: center*/}

          table {
          border: thin solid DarkBlue;
          padding: 0.3em;
          width: auto}
        </style>
      </head>
      <body>
        <xsl:apply-templates/>
      </body>
    </html>
  </xsl:template>

  <!-- error element -->
  <xsl:template match="r:ERROR">
    <div class="error">
      <h2>Error</h2>
      <p>
        <xsl:value-of select="r:MESSAGE"/>
      </p>
      <p>
        <xsl:value-of select="r:PACKAGE"/> rejected <xsl:value-of select="@REJECT_TIME"/>
      </p>
    </div>
  </xsl:template>

  <!-- ingest element -->
  <xsl:template match="r:INGEST">
    <div class="ingest">
      <h1>Ingest Report</h1>
      <table>
        <tr>
          <th>Package name</th>
          <th>Int. Entity ID</th>
          <th>Ingest time</th>
        </tr>
        <tr>
          <td><xsl:value-of select="@PACKAGE"/></td>
          <td><xsl:value-of select="@IEID"/></td>
          <td><xsl:value-of select="@INGEST_TIME"/></td>
        </tr>
      </table>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- refresh element -->
  <xsl:template match="r:REFRESH">
    <div class="refresh">
      <h1>Refresh Report</h1>
      <table>
        <tr>
          <th>Package name</th>
          <th>Int. Entity ID</th>
          <th>Ingest time</th>
        </tr>
        <tr>
          <td><xsl:value-of select="@PACKAGE"/></td>
          <td><xsl:value-of select="@IEID"/></td>
          <td><xsl:value-of select="@INGEST_TIME"/></td>
        </tr>
      </table>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- refresh element -->
  <xsl:template match="r:D1REFRESH">
    <div class="d1refresh">
      <h1>D1 Refresh Report</h1>
      <table>
        <tr>
          <th>Package name</th>
          <th>Int. Entity ID</th>
          <th>Ingest time</th>
        </tr>
        <tr>
          <td><xsl:value-of select="@PACKAGE"/></td>
          <td><xsl:value-of select="@IEID"/></td>
          <td><xsl:value-of select="@INGEST_TIME"/></td>
        </tr>
      </table>
      <xsl:apply-templates/>
    </div>
  </xsl:template>

  <!-- withdrawal element -->
  <xsl:template match="r:WITHDRAWAL">
    <div class="withdrawal">
      <h1>Withdrawal Report</h1>
      <table>
        <tr>
          <th>Package name</th>
          <td><xsl:value-of select="@PACKAGE_NAME"/></td>
        </tr>
        <tr>
          <th>Int. Entity ID</th>
          <td><xsl:value-of select="@IEID"/></td>
        </tr>
        <tr>
          <th>Withdrawal time</th>
          <td><xsl:value-of select="@WITHDRAWAL_TIME"/></td>
        </tr>
        <tr>
          <th>Note</th>
          <td><xsl:value-of select="@NOTE"/></td>
        </tr>
      </table>

      <!-- <xsl:apply-templates select="//r:AGREEMENT_INFO"/> -->

      <h3>Files</h3>
      <dl>
        <xsl:for-each select="r:FILE">
          <dt>
            <xsl:value-of select="@DFID"/>
          </dt>
          <dd>
            <table>
              <tr>
                <th>Path</th>
                <td><xsl:value-of select="@PATH"/></td>
              </tr>
              <tr>
                <th>Size</th>
                <td><xsl:value-of select="@SIZE"/></td>
              </tr>
              <xsl:for-each select="r:MESSAGE_DIGEST">
                <tr>
                  <th><xsl:value-of select="@ALGORITHM"/></th>
                  <td><xsl:value-of select="text()"/></td>
                </tr>
              </xsl:for-each>
            </table>
          </dd>
        </xsl:for-each>
      </dl>
    </div>
  </xsl:template>


  <!-- agreement info -->
  <xsl:template match="r:AGREEMENT_INFO">
    <div class="agreementInfo">
      <h2>Agreement Info</h3>
      <table>
        <tr>
          <th>Account:</th>
          <td><xsl:value-of select="@ACCOUNT"/></td>
        </tr>
        <tr>
          <th>Project:</th>
          <td><xsl:value-of select="@PROJECT"/></td>
        </tr>
      </table>
    </div>
  </xsl:template>

  <!-- Request Events -->
  <xsl:template match="r:REQUEST_EVENTS">
	<div class="requestEvents">
		<h2><xsl:value-of select="@TITLE"/></h2>	
		<table>
			<tr>
				<th>Type</th>
				<th>Time: </th>
				<th>agent ID: </th>
				<th>note: </th>
			</tr>
			<xsl:for-each select="r:REQUEST_EVENT">
				<tr>
					<td><xsl:value-of select="@NAME"/></td>
					<td><xsl:value-of select="@TIME"/></td>
					<td><xsl:value-of select="@AGENT"/></td>
					<td><xsl:value-of select="@NOTE"/></td>
				</tr>
			</xsl:for-each>
		</table>
	</div>
  </xsl:template>

  <!-- files element -->
  <xsl:template match="r:FILES">

    <!-- reportable files, for now just exclude the daitss namespace files -->
    <xsl:variable name="rfiles"
                  select="r:FILE[not(contains(@PATH, 'www.fcla.edu/dls/md/daitss'))]"/>
    <div class="files">
      <h3>Files</h3>

      <!-- general archival attributes -->
      <div class="archivalAttributes">
        <h4>Archival Attributes</h4>
        <table>
          <tr>
            <th>Id</th>
            <th>Name</th>
            <th>Size</th>
            <th>Origin</th>
            <th>Message Digests</th>
            <th>Events</th>
            <th>Broken Links</th>
            <th>Warnings</th>
          </tr>

          <xsl:for-each select="$rfiles">

            <tr>
              <td align="left">
                <a name="FILE_{@DFID}">
                  <xsl:value-of select="@DFID"/>
                </a>
              </td>
              <td align="left"><xsl:value-of select="@PATH"/></td>
              <td align="right"><xsl:value-of select="@SIZE"/></td>
              <td align="center"><xsl:value-of select="@ORIGIN"/></td>
              <td align="center">
                <a href="#MD_{@DFID}"><xsl:value-of select="count(r:MESSAGE_DIGEST)"/></a>
              </td>
              <td align="center">
                <xsl:choose>
                  <xsl:when test="count(r:EVENT) > 0">
                    <a href="#EV_{@DFID}">
                      <xsl:value-of select="count(r:EVENT)"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="count(r:EVENT)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
              <td align="center">
                <xsl:choose>
                  <xsl:when test="count( r:BROKEN_LINK ) > 0">
                    <a href="#BL_{@DFID}">
                      <xsl:value-of select="count(r:BROKEN_LINK)"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    0
                  </xsl:otherwise>
                </xsl:choose>
              </td>
              <td align="center">
                <xsl:choose>
                  <xsl:when test="count(r:WARNING) > 0">
                    <a href="#W_{@DFID}">
                      <xsl:value-of select="count(r:WARNING)"/>
                    </a>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="count(r:WARNING)"/>
                  </xsl:otherwise>
                </xsl:choose>
              </td>
            </tr>
          </xsl:for-each>
        </table>
      </div>

      <!-- message digests -->
      <div class="messageDigests">
        <h4>Message Digests</h4>
        <xsl:for-each select="$rfiles">
          <div class="ftitle">
            <a name="MD_{@DFID}" href="#FILE_{@DFID}">
              <xsl:value-of select="@DFID"/>
            </a>
          </div>
          <table>
            <tr>
              <th>
                Message Digest
              </th>
              <th>
                Algorithm
              </th>
            </tr>
            <xsl:for-each select="r:MESSAGE_DIGEST">
              <tr>
                <td><xsl:value-of select="."/></td>
                <td><xsl:value-of select="@ALGORITHM"/></td>
              </tr>
            </xsl:for-each>
          </table>
        </xsl:for-each>
      </div>

      <!-- events -->
      <div class="listing">
        <h4>Events</h4>
        <xsl:for-each select="$rfiles">
          <xsl:if test="count(r:EVENT) > 0">
            <div class="ftitle">
              <a name="EV_{@DFID}" href="#FILE_{@DFID}">
                <xsl:value-of select="@DFID"/>
              </a>
            </div>
            <ul>
              <xsl:for-each select="r:EVENT">
                <li class="data">
                  <xsl:value-of select="."/>
                </li>
              </xsl:for-each>
            </ul>
          </xsl:if>
        </xsl:for-each>
      </div>

      <!-- broken links -->
      <div class="listing">
        <h4>Broken Links</h4>
        <xsl:for-each select="$rfiles">
          <xsl:if test="count( r:BROKEN_LINK ) > 0">
            <div class="ftitle">
              <a name="BL_{@DFID}" href="#FILE_{@DFID}">
                <xsl:value-of select="@DFID"/>
              </a>
            </div>
            <ul>
              <xsl:for-each select="r:BROKEN_LINK">
                <li class="data">
                  <xsl:value-of select="."/>
                </li>
              </xsl:for-each>
            </ul>
          </xsl:if>
        </xsl:for-each>
      </div>

    </div>

    <!-- warnings -->
    <div class="listing">
      <h4>Warnings</h4>
      <xsl:for-each select="$rfiles">
        <xsl:if test="count(r:WARNING) > 0">
          <div class="ftitle">
            <a name="W_{@DFID}" href="#FILE_{@DFID}">
              <xsl:value-of select="@DFID"/>
            </a>
          </div>
          <ul>
            <xsl:for-each select="r:WARNING">
              <li class="data">
                <strong><xsl:value-of select="@CODE"/></strong>: <xsl:value-of select="."/>
              </li>
            </xsl:for-each>
          </ul>
        </xsl:if>
      </xsl:for-each>
    </div>


  </xsl:template>

</xsl:stylesheet>

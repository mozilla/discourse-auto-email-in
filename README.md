# auto-email-in
*Discourse plugin which automatically sets category email-in addresses based on their slug*

[![Build Status](https://travis-ci.org/mozilla/discourse-auto-email-in.svg?branch=master)](https://travis-ci.org/mozilla/discourse-auto-email-in)

## Bug reports

Bug reports should be filed [by following the process described here](https://discourse.mozilla.org/t/where-do-i-file-bug-reports-about-discourse/32078).

## Installation

Follow the Discourse [Install a Plugin](https://meta.discourse.org/t/install-a-plugin/19157) guide.

## Usage

If `auto_email_in_append` is enabled then this plugin won't overwrite existing email-in addresses, but will append newly generated addresses to the chain of possible addresses.

Then, if an admin manually edits the email in value, the generated address will be appended (if it doesn't already exist). This can be used to clear old addresses on categories.

If `auto_email_in_append` is disabled, then this plugin will overwrite all existing email-in addresses with the ones it generates, and admins won't be able to edit addresses.

## Licence

[MPL 2.0](https://www.mozilla.org/MPL/2.0/)

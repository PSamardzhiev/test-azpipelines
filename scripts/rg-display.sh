#!/bin/bash
echo "Listing the resource group below"
az group list --query '[].name' --out table
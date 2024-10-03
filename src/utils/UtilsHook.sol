//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

// some code from ENS Domains contracts

library UtilsHook {
    /*
     * @dev Returns the keccak-256 hash of a byte range.
     * @param self The byte string to hash.
     * @param offset The position to start hashing at.
     * @param len The number of bytes to hash.
     * @return The hash of the byte range.
     */
    function keccak(
        bytes memory self,
        uint256 offset,
        uint256 len
    ) internal pure returns (bytes32 ret) {
        require(offset + len <= self.length);
        assembly {
            ret := keccak256(add(add(self, 32), offset), len)
        }
    }

    /**
     * @dev Returns the ENS namehash of a DNS-encoded name.
     * @param self The DNS-encoded name to hash.
     * @param offset The offset at which to start hashing.
     * @return The namehash of the name.
     */
    function namehash(bytes memory self, uint256 offset)
        internal
        pure
        returns (bytes32)
    {
        (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
        if (labelhash == bytes32(0)) {
            require(offset == self.length - 1, "namehash: Junk at end of name");
            return bytes32(0);
        }
        return
            keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
    }

    /**
     * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
     * @param self The byte string to read a label from.
     * @param idx The index to read a label at.
     * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
     * @return newIdx The index of the start of the next label.
     */
    function readLabel(bytes memory self, uint256 idx)
        internal
        pure
        returns (bytes32 labelhash, uint256 newIdx)
    {
        require(idx < self.length, "readLabel: Index out of bounds");
        uint256 len = uint256(uint8(self[idx]));
        if (len > 0) {
            labelhash = keccak(self, idx + 1, len);
        } else {
            labelhash = bytes32(0);
        }
        newIdx = idx + len + 1;
    }

    /**
     * @dev This function takes a bytes input which represents the DNS name and
     * returns the first label of a domain name in DNS format.
     * @param domain The domain in DNS format wherein the length precedes each label
     * and is terminted with a 0x0 byte, e.g. "cb.id" => [0x02,0x63,0x62,0x02,0x69,0x64,0x00].
     * @return string memory the first label.
     */

    function getFirstLabel(bytes memory domain) internal pure returns (string memory, uint256) {

        // Get the first byte of the domain which represents the length of the first label
        uint256 labelLength = uint256(uint8(domain[0]));

        // Check to make sure the label length is less than the domain length and greater than zero. 
        require(labelLength < domain.length && labelLength > 0);

        // Create a new byte array to hold the first label
        bytes memory firstLabel = new bytes(labelLength);

        // Iterate through the domain bytes to copy the first label to the new byte array
        // skipping the first byte which represents the length of the first label.
        for (uint256 i = 0; i < labelLength; ++i) {
            firstLabel[i] = domain[i+1];
        }

        // Convert the first label to string and return, with the length of the first label.
        return (string(firstLabel), labelLength);
    }

    /**
     * @dev This function takes a bytes input which represents the DNS name and
     * returns the TLD (last label) of a domain name. A domain can have a maximum of 10 labels.
     * @param domain bytes memory.
     * @return string memory the TLD.
     */

    function getTLD(bytes memory domain) internal pure returns (string memory) {
        // Variable used to keep track of the level count.

        uint levels = 0;
        // Variable used to keep track of the index of each length byte.

        // Iterate through the domain bytes. 
        for (uint i = 0; i < domain.length; i++) {

            // If level count exceed 10, break the loop.
            if (levels > 10) {
                break;
            }

            // Get the label length from the current byte.
            uint labelLength = uint(uint8(domain[i]));

            // Check to make sure we have found the terminal byte and it is equal to zero.
            if(i + labelLength + 2 == domain.length && domain[labelLength + i + 1] == 0) {

                // Create a new byte array to hold the TLD.
                bytes memory lastLabel = new bytes(labelLength);

                // Copy the TLD from the domain array to the new byte array.
                for (uint j = 0; j < labelLength; j++) {
                    lastLabel[j] = domain[i + 1 + j];
                }

                // Convert the TLD to string and return.
                return string(lastLabel);
            }

            // Move to the next label
            i += labelLength;

            // Increment the level count.
            levels++;
        }

        // Revert if TLD not found.
        revert("TLD not found");
    }

    //"\x03123\x03eth\x00";

    function replaceTLD(bytes memory domain, bytes memory newTld) internal pure returns (string memory) {
        // Variable used to keep track of the level count.

        uint levels = 0;
        // Variable used to keep track of the index of each length byte.

        uint lastLabelLength = 0;

        // Iterate through the domain bytes. 
        for (uint i = 0; i < domain.length;) {

            // If level count exceed 10, break the loop.
            if (levels > 10) {

                break;
            }

            // Get the label length from the current byte.
            uint labelLength = uint(uint8(domain[i]));

            i += labelLength + 1;

            if (labelLength != 0) {

                lastLabelLength = labelLength;
                levels++;

                continue;
            }
        }

        if (levels <= 10) {
            uint newTldLength = newTld.length;

            bytes memory newName = new bytes(domain.length - lastLabelLength + newTldLength - 2);

            uint newNameLength = 0;

            for (uint i = 0; i < domain.length - (lastLabelLength + 2); i++) {

                newName[i] = domain[i];
                newNameLength++;
            }

            for (uint j = 0; j < newTldLength; j++) {

                newName[j + newNameLength] = newTld[j];
            }

            return string(newName);
        }

        // Revert if TLD not found.
        revert("TLD not found");
    }

    /**
     * @dev Converts a DNS-encoded name to a reverse string format.
     * For example, 0x0364616f0365746800 (which represents "dao.eth") becomes "eth.dao".
     * @param domain The DNS-encoded domain name.
     * @return The reversed domain name as a string.
     */
    function DNSNameToReverseString(bytes memory domain) internal pure returns (string memory) {
        uint256 len = domain.length;
        uint256 labelCount = 0;

        // First, count the number of labels in the domain using a for loop
        for (uint256 i = 0; i < len; ) {
            // Read the length of the label
            uint256 labelLen = uint256(uint8(domain[i]));
            if (labelLen == 0) {
                break;
            }
            labelCount++;
            i += labelLen + 1;
        }

        // Create an array to hold the labels
        bytes[] memory labels = new bytes[](labelCount);

        // Parse the labels and store them using a for loop
        uint256 labelIndex = 0;
        for (uint256 i = 0; i < len;) {
            uint256 labelLen = uint256(uint8(domain[i]));
            if (labelLen == 0) {
                break;
            }
            bytes memory label = new bytes(labelLen);
            for (uint256 j = 0; j < labelLen; j++) {
                label[j] = domain[i + 1 + j];
            }
            labels[labelIndex] = label;
            labelIndex++;
            i += labelLen + 1;
        }

        // Reverse the labels and concatenate them with dots using a for loop
        bytes memory reversedName;
        for (uint256 k = 0; k < labelCount; k++) {
            uint256 idx = labelCount - 1 - k;
            bytes memory label = labels[idx];
            if (k > 0) {
                reversedName = abi.encodePacked(reversedName, ".", label);
            } else {
                reversedName = abi.encodePacked(label);
            }
        }
        return string(reversedName);
    }

        /**
     * @dev Converts a domain in reverse string format to DNS-encoded format.
     * For example, "eth.dao" becomes 0x0364616f0365746800 (which represents "dao.eth").
     * @param domain The reverse domain name as a string.
     * @return The DNS-encoded domain name as bytes.
     */
    function reverseStringToDNS(string memory domain) internal pure returns (bytes memory) {
        bytes memory domainBytes = bytes(domain);
        uint256 len = domainBytes.length;

        // Count the number of labels in the domain
        uint256 labelCount = 1; // At least one label
        for (uint256 i = 0; i < len; i++) {
            if (domainBytes[i] == ".") {
                labelCount++;
            }
        }

        // Store the start and end indices of each label
        uint256[] memory labelStarts = new uint256[](labelCount);
        uint256[] memory labelEnds = new uint256[](labelCount);

        uint256 labelIndex = 0;
        uint256 start = 0;
        for (uint256 i = 0; i <= len; i++) {
            if (i == len || domainBytes[i] == ".") {
                labelStarts[labelIndex] = start;
                labelEnds[labelIndex] = i;
                labelIndex++;
                start = i + 1;
            }
        }

        // Reverse the labels to get the original domain order
        bytes memory dnsName;
        for (uint256 i = labelCount; i > 0; i--) {
            uint256 idx = i - 1;
            uint256 labelLen = labelEnds[idx] - labelStarts[idx];
            require(labelLen > 0 && labelLen <= 63, "Invalid label length");
            dnsName = abi.encodePacked(dnsName, bytes1(uint8(labelLen)));
            for (uint256 j = labelStarts[idx]; j < labelEnds[idx]; j++) {
                dnsName = abi.encodePacked(dnsName, domainBytes[j]);
            }
        }

        // Append the zero-length label at the end
        dnsName = abi.encodePacked(dnsName, bytes1(0x00));

        return dnsName;
    }

    /**
     * @dev Splits a string into the first `numLabels` labels and the rest.
     * For example, with numLabels = 2, "eth.dao.votes.latest" becomes ("eth.dao", "votes.latest").
     * If there are not dots, then return the whole string in the firstLabels.
     * @param reverseDomain The reverse domain name as a string.
     * @param numLabels The number of labels to include in the first part.
     * @return firstLabels The first `numLabels` labels concatenated with dots.
     * @return remainingLabels The remaining labels concatenated with dots.
     */
    function splitOnDot(string memory reverseDomain, uint256 numLabels)
        internal
        pure
        returns (string memory firstLabels, string memory remainingLabels)
    {
        require(numLabels > 0, "Number of labels must be greater than zero");

        bytes memory domainBytes = bytes(reverseDomain);
        uint256 len = domainBytes.length;

        // Arrays to hold the positions of dots in the domain
        uint256[] memory dotPositions = new uint256[](len);
        uint256 dotCount = 0;

        // Record the positions of dots
        for (uint256 i = 0; i < len; i++) {
            if (domainBytes[i] == ".") {
                dotPositions[dotCount++] = i;
            }
        }

        // If there is only one label, return the whole string as firstLabels
        if (dotCount == 0) {
            return (reverseDomain, "");
        }

        require(dotCount + 1 >= numLabels, "Domain has fewer labels than specified");

        uint256 splitPosition;

        if (numLabels == 1) {
            // Split after the first label
            splitPosition = dotCount > 0 ? dotPositions[0] : len;
        } else {
            // Ensure there are enough dots to split
            require(dotCount >= numLabels - 1, "Not enough labels to split");
            splitPosition = dotPositions[numLabels - 1];
        }

        // Extract the first `numLabels` labels
        bytes memory firstLabelsBytes = new bytes(splitPosition);
        for (uint256 i = 0; i < splitPosition; i++) {
            firstLabelsBytes[i] = domainBytes[i];
        }
        firstLabels = string(firstLabelsBytes);

        // Extract the remaining labels
        if (splitPosition < len) {
            uint256 remainingLength = len - splitPosition - 1; // Exclude the dot
            bytes memory remainingBytes = new bytes(remainingLength);
            for (uint256 i = 0; i < remainingLength; i++) {
                remainingBytes[i] = domainBytes[splitPosition + 1 + i];
            }
            remainingLabels = string(remainingBytes);
        } else {
            remainingLabels = "";
        }
    }


}
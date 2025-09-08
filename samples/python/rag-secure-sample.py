# Copilot RAG Pipeline Simulation
# Demonstrates how Copilot grounds responses using enterprise data

import numpy as np
from typing import List, Dict, Tuple
import hashlib

class CopilotRAGPipeline:
    """
    Simulates the RAG pipeline used by Microsoft 365 Copilot
    Based on Microsoft documentation and architecture
    """
    
    def __init__(self, graph_client, semantic_index):
        self.graph = graph_client
        self.index = semantic_index
        self.embeddings_cache = {}
        
    def process_user_prompt(self, prompt: str, user_context: Dict) -> Dict:
        """
        Main pipeline for processing user prompts
        """
        # Step 1: Query understanding and expansion
        expanded_query = self._expand_query(prompt, user_context)
        
        # Step 2: Retrieve from Microsoft Graph
        graph_results = self._search_graph(expanded_query, user_context['user_id'])
        
        # Step 3: Retrieve from Semantic Index
        semantic_results = self._search_semantic_index(expanded_query)
        
        # Step 4: Combine and rank results
        combined_results = self._merge_and_rank(graph_results, semantic_results)
        
        # Step 5: Apply security trimming
        filtered_results = self._apply_security_trimming(
            combined_results, 
            user_context['permissions']
        )
        
        # Step 6: Generate grounded prompt
        grounded_prompt = self._create_grounded_prompt(
            prompt, 
            filtered_results, 
            user_context
        )
        
        return {
            'grounded_prompt': grounded_prompt,
            'sources': filtered_results[:5],  # Top 5 sources
            'metadata': {
                'graph_results': len(graph_results),
                'semantic_results': len(semantic_results),
                'filtered_results': len(filtered_results)
            }
        }
    
    def _expand_query(self, prompt: str, context: Dict) -> str:
        """
        Expands user query with context and synonyms
        """
        # Add temporal context
        time_context = f"current date: {context.get('current_date', 'unknown')}"
        
        # Add user context
        user_context = f"user role: {context.get('role', 'unknown')}"
        
        # Add organizational context
        org_context = f"department: {context.get('department', 'unknown')}"
        
        expanded = f"{prompt}\n\nContext:\n{time_context}\n{user_context}\n{org_context}"
        
        return expanded
    
    def _search_graph(self, query: str, user_id: str) -> List[Dict]:
        """
        Searches Microsoft Graph for relevant content
        """
        # Simulate Graph API search across multiple endpoints
        endpoints = [
            '/search/query',  # Unified search
            f'/users/{user_id}/messages',  # User's emails
            f'/users/{user_id}/drive/root/search',  # OneDrive files
            '/sites/root/lists',  # SharePoint lists
        ]
        
        results = []
        for endpoint in endpoints:
            # Simulate API call with proper scopes
            api_results = self._call_graph_api(endpoint, query)
            results.extend(api_results)
        
        return results
    
    def _search_semantic_index(self, query: str) -> List[Dict]:
        """
        Searches the semantic index using vector similarity
        """
        # Generate embedding for query
        query_embedding = self._generate_embedding(query)
        
        # Find similar vectors in index
        similar_docs = self.index.search(
            vector=query_embedding,
            top_k=50,
            threshold=0.7  # Similarity threshold
        )
        
        return similar_docs
    
    def _generate_embedding(self, text: str) -> np.ndarray:
        """
        Generates vector embedding for text
        Simulates the embedding model used by Copilot
        """
        # Cache embeddings for performance
        text_hash = hashlib.md5(text.encode()).hexdigest()
        
        if text_hash in self.embeddings_cache:
            return self.embeddings_cache[text_hash]
        
        # Simulate embedding generation (768-dimensional vector)
        # In reality, this would use Ada or similar model
        embedding = np.random.randn(768)
        embedding = embedding / np.linalg.norm(embedding)  # Normalize
        
        self.embeddings_cache[text_hash] = embedding
        return embedding
    
    def _merge_and_rank(self, graph_results: List, semantic_results: List) -> List:
        """
        Merges and ranks results from different sources
        """
        all_results = []
        
        # Add graph results with source weight
        for result in graph_results:
            result['source_weight'] = 1.0  # Direct Graph results have high weight
            result['source_type'] = 'graph'
            all_results.append(result)
        
        # Add semantic results
        for result in semantic_results:
            result['source_weight'] = 0.8  # Semantic results slightly lower weight
            result['source_type'] = 'semantic'
            all_results.append(result)
        
        # Remove duplicates based on content hash
        seen = set()
        unique_results = []
        for result in all_results:
            content_hash = hashlib.md5(
                str(result.get('content', '')).encode()
            ).hexdigest()
            
            if content_hash not in seen:
                seen.add(content_hash)
                unique_results.append(result)
        
        # Rank by relevance score * source weight
        ranked = sorted(
            unique_results,
            key=lambda x: x.get('relevance_score', 0) * x.get('source_weight', 1),
            reverse=True
        )
        
        return ranked
    
    def _apply_security_trimming(self, results: List, permissions: Dict) -> List:
        """
        Applies security trimming based on user permissions
        Critical for maintaining data boundaries
        """
        filtered = []
        
        for result in results:
            # Check sensitivity label permissions
            if 'sensitivity_label' in result:
                label = result['sensitivity_label']
                if label == 'HighlyConfidential' and not permissions.get('highly_confidential_access'):
                    continue  # Skip this result
            
            # Check sharing permissions
            if 'permissions' in result:
                if not self._check_permissions(result['permissions'], permissions):
                    continue
            
            # Check information barriers
            if 'information_barrier' in result:
                if result['information_barrier'] not in permissions.get('allowed_barriers', []):
                    continue
            
            filtered.append(result)
        
        return filtered
    
    def _create_grounded_prompt(self, original_prompt: str, 
                                sources: List, context: Dict) -> str:
        """
        Creates the final grounded prompt for the LLM
        """
        grounded = f"User Query: {original_prompt}\n\n"
        grounded += "Relevant Information from your organization:\n\n"
        
        for i, source in enumerate(sources[:5], 1):  # Limit to top 5 sources
            grounded += f"Source {i} ({source['source_type']}):\n"
            grounded += f"Title: {source.get('title', 'Untitled')}\n"
            grounded += f"Content: {source.get('content', '')[:500]}...\n"  # Truncate
            grounded += f"Last Modified: {source.get('modified_date', 'Unknown')}\n"
            grounded += f"Relevance Score: {source.get('relevance_score', 0):.2f}\n\n"
        
        grounded += "\nInstructions: Provide a response based on the above sources. "
        grounded += "Cite sources when making specific claims. "
        grounded += "If the sources don't contain relevant information, indicate this clearly."
        
        return grounded
    
    def _call_graph_api(self, endpoint: str, query: str) -> List[Dict]:
        """
        Simulates Graph API call with proper authentication
        """
        # In production, this would use actual Graph SDK
        # with proper OAuth2 token including required scopes
        
        # Simulated response structure
        return [
            {
                'id': f'graph_{endpoint}_{i}',
                'content': f'Sample content for {query}',
                'title': f'Document {i}',
                'relevance_score': np.random.random(),
                'modified_date': '2024-09-01',
                'permissions': ['user@contoso.com'],
                'sensitivity_label': 'Internal'
            }
            for i in range(3)
        ]
    
    def _check_permissions(self, resource_permissions: List, 
                          user_permissions: Dict) -> bool:
        """
        Validates if user has access to resource
        """
        # Check if user is in allowed list
        if user_permissions.get('user_id') in resource_permissions:
            return True
        
        # Check group memberships
        user_groups = user_permissions.get('groups', [])
        for group in user_groups:
            if group in resource_permissions:
                return True
        
        return False

# Usage example
def simulate_copilot_rag():
    """
    Demonstrates the RAG pipeline in action
    """
    # Initialize components
    graph_client = None  # Would be actual Graph client
    semantic_index = None  # Would be actual semantic index
    
    pipeline = CopilotRAGPipeline(graph_client, semantic_index)
    
    # User context
    user_context = {
        'user_id': 'user@contoso.com',
        'role': 'Finance Manager',
        'department': 'Finance',
        'current_date': '2024-09-05',
        'permissions': {
            'groups': ['Finance', 'Managers'],
            'highly_confidential_access': False,
            'allowed_barriers': ['Finance', 'Corporate']
        }
    }
    
    # Process a user prompt
    prompt = "What were the key findings from last quarter's financial review?"
    
    result = pipeline.process_user_prompt(prompt, user_context)
    
    print(f"Original Prompt: {prompt}")
    print(f"\nSources Found: {result['metadata']['filtered_results']}")
    print(f"Graph Results: {result['metadata']['graph_results']}")
    print(f"Semantic Results: {result['metadata']['semantic_results']}")
    print(f"\nGrounded Prompt (first 500 chars):\n{result['grounded_prompt'][:500]}...")
    
    return result